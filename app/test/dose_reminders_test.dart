import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/phone_fakes.dart';

/// 08:00 in Riyadh on 3 November 2026.
final DateTime _now = DateTime.utc(2026, 11, 3, 5);

const ReminderCircle _noura = ReminderCircle(id: 'c-noura', name: 'أمي نورة');
const ReminderCircle _me = ReminderCircle(id: 'c-me', name: 'صحتي');

final DoseReminderTexts _texts = DoseReminderTexts(
  title: (ReminderCircle circle) => 'دواء ${circle.name}',
  body: (DoseOccurrence dose) => dose.name,
  keepTitle: () => 'keep',
  keepBody: () => 'open the app',
);

/// A dose on [day] (of November 2026) at [time] in Riyadh.
DoseOccurrence _dose(
  int day,
  String time, {
  String name = 'ميتفورمين',
  DoseRecord? record,
}) => DoseOccurrence(
  planId: 'plan-$name',
  scheduleId: 'schedule-$name-$time',
  scheduledOn: DateTime(2026, 11, day),
  time: time,
  name: name,
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  record: record,
);

final DoseRecord _taken = DoseRecord(
  id: 'record-1',
  outcome: DoseOutcome.taken,
  recordedAt: DateTime.utc(2026, 11, 3, 5),
  takenAt: DateTime.utc(2026, 11, 3, 5),
);

/// The doses of each circle, and the readings the reminders asked for.
class _Medications extends Fake implements MedicationsRepositoryDomain {
  final Map<String, List<DoseOccurrence>> doses =
      <String, List<DoseOccurrence>>{};
  final List<(String, DateTime, DateTime)> reads =
      <(String, DateTime, DateTime)>[];

  /// When set, a reading answers with it.
  Result<List<DoseOccurrence>, Failure>? answer;

  /// When set, a reading waits for it.
  Completer<void>? gate;

  @override
  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    reads.add((circleId, from, to));
    final Completer<void>? wait = gate;
    if (wait != null) await wait.future;
    return answer ??
        Success<List<DoseOccurrence>, Failure>(
          doses[circleId] ?? const <DoseOccurrence>[],
        );
  }

  @override
  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) async => Success<DoseRecord, Failure>(_taken);
}

void main() {
  group('planning', () {
    test('a dose time in Riyadh is the same moment on any phone', () {
      expect(doseMoment(_dose(3, '08:30')), DateTime.utc(2026, 11, 3, 5, 30));
      // Just after midnight in Riyadh is the day before in UTC.
      expect(doseMoment(_dose(4, '01:00')), DateTime.utc(2026, 11, 3, 22));
    });

    test('one reminder per dose to come, the nearest first, then the note',
        () {
      final List<ScheduledNotification> planned = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[
          (_noura, _dose(3, '21:00')),
          (_me, _dose(3, '12:00', name: 'فيتامين د')),
          (_noura, _dose(4, '08:00')),
        ],
        now: _now,
        texts: _texts,
      );

      expect(planned, hasLength(4));
      expect(planned[0].at, DateTime.utc(2026, 11, 3, 9));
      expect(planned[0].title, 'دواء صحتي');
      expect(planned[0].body, 'فيتامين د');
      expect(planned[0].payload, 'dose:c-me');
      expect(planned[0].thread, 'c-me');
      expect(planned[1].at, DateTime.utc(2026, 11, 3, 18));
      expect(planned[1].title, 'دواء أمي نورة');
      expect(planned[2].at, DateTime.utc(2026, 11, 4, 5));
      // The note comes a minute after the last reminder.
      expect(planned[3].payload, keepRemindersPayload);
      expect(planned[3].at, DateTime.utc(2026, 11, 4, 5, 1));
      expect(planned[3].title, 'keep');
      expect(
        planned.map((ScheduledNotification n) => n.id).toSet(),
        hasLength(4),
      );
    });

    test('no reminder for a dose already marked, gone, or too close', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[
          (_noura, _dose(3, '09:00', record: _taken)),
          (_noura, _dose(3, '07:00')),
          // In less than a minute.
          (_noura, _dose(3, '08:00')),
        ],
        now: _now,
        texts: _texts,
      );

      expect(planned, isEmpty);
    });

    test('at most 60 reminders, the nearest ones, and the note', () {
      final List<(ReminderCircle, DoseOccurrence)> many =
          <(ReminderCircle, DoseOccurrence)>[
            for (int day = 4; day <= 10; day++)
              for (int hour = 9; hour < 19; hour++)
                (_noura, _dose(day, '$hour:00', name: 'دواء $day $hour')),
          ];

      final List<ScheduledNotification> planned = planDoseReminders(
        doses: many,
        now: _now,
        texts: _texts,
      );

      expect(many, hasLength(70));
      expect(planned, hasLength(maxDoseReminders + 1));
      expect(planned.first.body, 'دواء 4 9');
      expect(planned[maxDoseReminders - 1].body, 'دواء 9 18');
      expect(planned.last.payload, keepRemindersPayload);
    });
  });

  group('keeping the reminders on the phone', () {
    late _Medications medications;
    late MedicationsUseCase useCase;
    late FakePhoneNotifications phone;
    late DoseReminders reminders;

    setUp(() {
      medications = _Medications();
      useCase = MedicationsUseCase(medications);
      phone = FakePhoneNotifications();
      reminders = DoseReminders(
        useCase,
        phone,
        texts: _texts,
        clock: () => _now,
      );
    });

    /// Lets a reading started by a change finish.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('sets the reminders of every circle and asks once', () async {
      medications.doses[_noura.id] = <DoseOccurrence>[_dose(3, '21:00')];
      medications.doses[_me.id] = <DoseOccurrence>[
        _dose(3, '12:00', name: 'فيتامين د'),
      ];

      await reminders.sync(<ReminderCircle>[_noura, _me]);

      expect(
        phone.inOrder.map((ScheduledNotification n) => n.payload),
        <String>['dose:c-me', 'dose:c-noura', keepRemindersPayload],
      );
      expect(phone.permissionRequests, 1);

      await reminders.refresh();
      expect(phone.permissionRequests, 1);
    });

    test('reads a week, from today in Riyadh', () async {
      await reminders.sync(<ReminderCircle>[_noura]);

      expect(medications.reads.single, (
        'c-noura',
        DateTime.utc(2026, 11, 3),
        DateTime.utc(2026, 11, 9),
      ));
    });

    test('nothing to remind asks nothing', () async {
      await reminders.sync(<ReminderCircle>[_noura]);

      expect(phone.scheduled, isEmpty);
      expect(phone.permissionRequests, 0);
    });

    test('a dose marked in the app loses its reminder', () async {
      medications.doses[_noura.id] = <DoseOccurrence>[
        _dose(3, '12:00'),
        _dose(3, '21:00'),
      ];
      await reminders.sync(<ReminderCircle>[_noura]);
      expect(phone.scheduled, hasLength(3));

      // The server now has the 12:00 dose taken.
      medications.doses[_noura.id] = <DoseOccurrence>[
        _dose(3, '12:00', record: _taken),
        _dose(3, '21:00'),
      ];
      await useCase.recordDose(
        _noura.id,
        _dose(3, '12:00'),
        const DoseRecordDraft(outcome: DoseOutcome.taken),
      );
      await settle();
      await settle();

      expect(
        phone.inOrder.map((ScheduledNotification n) => n.at),
        <DateTime>[
          DateTime.utc(2026, 11, 3, 18),
          DateTime.utc(2026, 11, 3, 18, 1),
        ],
      );
    });

    test('a failed reading keeps the reminders already set', () async {
      medications.doses[_noura.id] = <DoseOccurrence>[_dose(3, '21:00')];
      await reminders.sync(<ReminderCircle>[_noura]);

      medications.answer = const Error(NetworkFailure());
      await reminders.refresh();

      expect(phone.scheduled, hasLength(2));
    });

    test('signing out removes them, even a reading on its way', () async {
      medications.doses[_noura.id] = <DoseOccurrence>[_dose(3, '21:00')];
      await reminders.sync(<ReminderCircle>[_noura]);
      medications.gate = Completer<void>();
      final Future<void> reading = reminders.refresh();

      await reminders.clear();
      medications.gate!.complete();
      await reading;

      expect(phone.cancelAlls, 1);
      expect(phone.scheduled, isEmpty);
    });

    test('a call during a reading makes one more reading after it', () async {
      medications.gate = Completer<void>();
      final Future<void> first = reminders.sync(<ReminderCircle>[_noura]);
      unawaited(reminders.refresh());
      unawaited(reminders.refresh());

      medications.gate!.complete();
      await first;
      await settle();
      await settle();

      expect(medications.reads, hasLength(2));
    });

    test('no circles: no reminders', () async {
      medications.doses[_noura.id] = <DoseOccurrence>[_dose(3, '21:00')];
      await reminders.sync(<ReminderCircle>[_noura]);

      await reminders.sync(const <ReminderCircle>[]);

      expect(phone.scheduled, isEmpty);
    });

    test('other notifications are left as they are', () async {
      await phone.schedule(
        ScheduledNotification(
          id: 1,
          at: DateTime.utc(2026, 11, 5),
          title: 'other',
          body: 'other',
          payload: 'something-else',
        ),
      );

      await reminders.sync(<ReminderCircle>[_noura]);

      expect(phone.scheduled.keys.toList(), <int>[1]);
    });
  });
}
