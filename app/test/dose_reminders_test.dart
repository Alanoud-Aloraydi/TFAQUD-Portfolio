import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
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
  title: (ReminderCircle circle, DoseOccurrence dose) => 'دواء ${circle.name}',
  body: (ReminderCircle circle, DoseOccurrence dose) => dose.name,
  measurementTitle: (ReminderCircle circle) => 'قياس ${circle.name}',
  measurementBody: (ReminderCircle circle, MeasurementOccurrence task) =>
      task.kind.name,
  appointmentTitle:
      (ReminderCircle circle, AppointmentLead lead, CareAppointment visit) =>
          'موعد ${circle.name} ${lead.name}',
  appointmentBody: (CareAppointment visit) => visit.specialty,
  keepTitle: () => 'keep',
  keepBody: () => 'open the app',
);

/// A payload without the words a snoozable reminder carries.
String _plain(String payload) => payload.split('\u001F').first;

/// A measurement task on [day] (of November 2026) at [time] in Riyadh.
MeasurementOccurrence _measurement(
  int day,
  String time, {
  MeasurementKind kind = MeasurementKind.glucose,
  MeasurementStatus status = MeasurementStatus.upcoming,
}) => MeasurementOccurrence(
  planId: 'plan-${kind.name}',
  versionId: 'version-${kind.name}',
  kind: kind,
  scheduledOn: DateTime(2026, 11, day),
  time: time,
  deadlineAt: DateTime.utc(2026, 11, day, 23),
  status: status,
);

/// An appointment on [day] (of November 2026) at [time] in Riyadh.
CareAppointment _appointment(
  int day,
  String time, {
  AppointmentStatus status = AppointmentStatus.scheduled,
}) => CareAppointment(
  id: 'appointment-$day',
  specialty: 'القلب',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, day),
  time: time,
  place: 'مستشفى',
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: status,
  updatedAt: DateTime.utc(2026, 11),
);

/// The measurement tasks of each circle.
class _Measurements extends Fake implements MeasurementRepository {
  final Map<String, List<MeasurementOccurrence>> tasks =
      <String, List<MeasurementOccurrence>>{};
  final StreamController<String> changed =
      StreamController<String>.broadcast();
  final StreamController<String> recordedNow =
      StreamController<String>.broadcast();
  bool offline = false;

  @override
  Stream<String> get changes => changed.stream;

  @override
  Stream<String> get recorded => recordedNow.stream;

  @override
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async {
    if (offline) throw Exception('offline');
    return tasks[circleId] ?? const <MeasurementOccurrence>[];
  }
}

/// The appointments of each circle.
class _Appointments extends Fake implements AppointmentRepository {
  final Map<String, List<CareAppointment>> visits =
      <String, List<CareAppointment>>{};
  final StreamController<String> changed =
      StreamController<String>.broadcast();

  @override
  Stream<String> get changes => changed.stream;

  @override
  Future<List<CareAppointment>> appointments(String circleId) async =>
      visits[circleId] ?? const <CareAppointment>[];
}

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
      expect(_plain(planned[0].payload), 'dose:c-me');
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

    test('a measurement to come is reminded at its time', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        measurements: <(ReminderCircle, MeasurementOccurrence)>[
          (_noura, _measurement(3, '10:00', kind: MeasurementKind.bp)),
          // Already read, skipped, or missed: nothing to remind of.
          (_noura, _measurement(3, '11:00', status: MeasurementStatus.read)),
          (
            _noura,
            _measurement(3, '12:00', status: MeasurementStatus.skipped),
          ),
          (_noura, _measurement(3, '07:00', status: MeasurementStatus.missed)),
        ],
        now: _now,
        texts: _texts,
      );

      expect(planned, hasLength(2));
      expect(planned[0].at, DateTime.utc(2026, 11, 3, 7));
      expect(planned[0].title, 'قياس أمي نورة');
      expect(planned[0].body, 'bp');
      expect(_plain(planned[0].payload), 'measurement:c-noura');
      expect(planned[0].thread, 'c-noura');
      expect(planned[1].payload, keepRemindersPayload);
    });

    test('an appointment is reminded a day before and two hours before', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        appointments: <(ReminderCircle, CareAppointment)>[
          (_noura, _appointment(5, '16:30')),
          (
            _noura,
            _appointment(6, '09:00', status: AppointmentStatus.cancelled),
          ),
        ],
        now: _now,
        texts: _texts,
      );

      expect(planned, hasLength(3));
      // 16:30 in Riyadh on the 4th, then 14:30 in Riyadh on the 5th.
      expect(planned[0].at, DateTime.utc(2026, 11, 4, 13, 30));
      expect(planned[0].title, 'موعد أمي نورة dayBefore');
      expect(planned[0].body, 'القلب');
      expect(planned[0].payload, 'appointment:c-noura');
      expect(planned[1].at, DateTime.utc(2026, 11, 5, 11, 30));
      expect(planned[1].title, 'موعد أمي نورة soon');
      expect(planned[2].payload, keepRemindersPayload);
    });

    test('an appointment added for today keeps only the near reminder', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        appointments: <(ReminderCircle, CareAppointment)>[
          (_noura, _appointment(3, '15:00')),
        ],
        now: _now,
        texts: _texts,
      );

      expect(planned.first.at, DateTime.utc(2026, 11, 3, 10));
      expect(planned.first.title, 'موعد أمي نورة soon');
      expect(planned, hasLength(2));
    });

    test('doses, measurements and appointments share one order', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[(_me, _dose(4, '20:00'))],
        measurements: <(ReminderCircle, MeasurementOccurrence)>[
          (_noura, _measurement(3, '09:00')),
        ],
        appointments: <(ReminderCircle, CareAppointment)>[
          (_noura, _appointment(4, '12:00')),
        ],
        now: _now,
        texts: _texts,
      );

      expect(planned.map((ScheduledNotification n) => _plain(n.payload)), <String>[
        'measurement:c-noura',
        'appointment:c-noura',
        'appointment:c-noura',
        'dose:c-me',
        keepRemindersPayload,
      ]);
      expect(
        planned.map((ScheduledNotification n) => n.id),
        <int>[7000, 7001, 7002, 7003, 7000 + maxDoseReminders],
      );
    });

    test('nothing at or after the end of the week read', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        appointments: <(ReminderCircle, CareAppointment)>[
          (_noura, _appointment(20, '10:00')),
        ],
        now: _now,
        texts: _texts,
        until: DateTime.utc(2026, 11, 9, 21),
      );

      expect(planned, isEmpty);
    });

    test('a dose or measurement carries its words for a snooze', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[(_me, _dose(3, '21:00'))],
        appointments: <(ReminderCircle, CareAppointment)>[
          (_noura, _appointment(5, '16:30')),
        ],
        now: _now,
        texts: _texts,
      );

      final ScheduledNotification dose = planned.firstWhere(
        (ScheduledNotification n) => n.payload.startsWith('dose:'),
      );
      expect(dose.snoozable, isTrue);
      expect(reminderText(dose.payload), (dose.title, dose.body));
      expect(reminderCircleId(dose.payload), 'c-me');
      expect(reminderCircleId('$snoozeTapPrefix${dose.payload}'), 'c-me');
      final ScheduledNotification visit = planned.firstWhere(
        (ScheduledNotification n) => n.payload.startsWith('appointment:'),
      );
      expect(visit.snoozable, isFalse);
      expect(visit.payload, 'appointment:c-noura');
    });

    test('the circle of a tapped reminder', () {
      expect(reminderCircleId('dose:c-1'), 'c-1');
      expect(reminderCircleId('measurement:c-2'), 'c-2');
      expect(reminderCircleId('appointment:c-3'), 'c-3');
      expect(reminderCircleId('dose-snooze:c-4'), 'c-4');
      expect(reminderCircleId(keepRemindersPayload), isNull);
      expect(reminderCircleId('invitation'), isNull);
      expect(isReminderPayload('measurement:c-2'), isTrue);
      expect(isReminderPayload('appointment:c-3'), isTrue);
      expect(isReminderPayload('dose-snooze:c-4'), isFalse);
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

    test('«ذكّرني لاحقًا» in a notification sets it again', () async {
      medications.doses[_me.id] = <DoseOccurrence>[_dose(3, '21:00')];
      await reminders.sync(<ReminderCircle>[_me]);
      final ScheduledNotification dose = phone.inOrder.first;

      expect(await reminders.snoozeTap(dose.payload), isFalse);
      expect(await reminders.snoozeTap('$snoozeTapPrefix${dose.payload}'), isTrue);

      final ScheduledNotification again = phone.scheduled[doseSnoozeId]!;
      expect(again.title, dose.title);
      expect(again.body, dose.body);
      expect(again.snoozable, isTrue);
      expect(reminderCircleId(again.payload), 'c-me');
    });

    test('sets the reminders of every circle and asks once', () async {
      medications.doses[_noura.id] = <DoseOccurrence>[_dose(3, '21:00')];
      medications.doses[_me.id] = <DoseOccurrence>[
        _dose(3, '12:00', name: 'فيتامين د'),
      ];

      await reminders.sync(<ReminderCircle>[_noura, _me]);

      expect(
        phone.inOrder.map((ScheduledNotification n) => _plain(n.payload)),
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

  group('measurements and appointments on the phone', () {
    late _Medications medications;
    late _Measurements measurements;
    late _Appointments appointments;
    late FakePhoneNotifications phone;
    late DoseReminders reminders;

    setUp(() {
      medications = _Medications();
      measurements = _Measurements();
      appointments = _Appointments();
      phone = FakePhoneNotifications();
      reminders = DoseReminders(
        MedicationsUseCase(medications),
        phone,
        texts: _texts,
        measurements: measurements,
        appointments: appointments,
        clock: () => _now,
      );
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('sets them with the doses', () async {
      medications.doses[_noura.id] = <DoseOccurrence>[_dose(3, '21:00')];
      measurements.tasks[_noura.id] = <MeasurementOccurrence>[
        _measurement(3, '10:00'),
      ];
      appointments.visits[_noura.id] = <CareAppointment>[
        _appointment(5, '16:30'),
        // Beyond the week read: set at a later opening.
        _appointment(25, '16:30'),
      ];

      await reminders.sync(<ReminderCircle>[_noura]);

      expect(
        phone.inOrder.map((ScheduledNotification n) => _plain(n.payload)),
        <String>[
          'measurement:c-noura',
          'dose:c-noura',
          'appointment:c-noura',
          'appointment:c-noura',
          keepRemindersPayload,
        ],
      );
    });

    test('a recorded measurement loses its reminder', () async {
      measurements.tasks[_noura.id] = <MeasurementOccurrence>[
        _measurement(3, '10:00'),
      ];
      await reminders.sync(<ReminderCircle>[_noura]);
      expect(phone.scheduled, hasLength(2));

      measurements.tasks[_noura.id] = <MeasurementOccurrence>[
        _measurement(3, '10:00', status: MeasurementStatus.read),
      ];
      measurements.recordedNow.add(_noura.id);
      await settle();
      await settle();

      expect(phone.scheduled, isEmpty);
    });

    test('a cancelled appointment loses its reminders', () async {
      appointments.visits[_noura.id] = <CareAppointment>[
        _appointment(5, '16:30'),
      ];
      await reminders.sync(<ReminderCircle>[_noura]);
      expect(phone.scheduled, hasLength(3));

      appointments.visits[_noura.id] = <CareAppointment>[
        _appointment(5, '16:30', status: AppointmentStatus.cancelled),
      ];
      appointments.changed.add(_noura.id);
      await settle();
      await settle();

      expect(phone.scheduled, isEmpty);
    });

    test('a failed measurement reading keeps what is set', () async {
      measurements.tasks[_noura.id] = <MeasurementOccurrence>[
        _measurement(3, '10:00'),
      ];
      await reminders.sync(<ReminderCircle>[_noura]);

      measurements.offline = true;
      await reminders.refresh();

      expect(phone.scheduled, hasLength(2));
    });
  });
}
