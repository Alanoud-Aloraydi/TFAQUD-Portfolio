import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/phone_fakes.dart';

/// 08:00 in Riyadh on 3 November 2026.
final DateTime _now = DateTime.utc(2026, 11, 3, 5);

/// The zone where both patients live.
const String _riyadh = 'Asia/Riyadh';

/// The account of the person on this phone.
const String _meId = 'a-me';

/// Noura's circle, where the person on this phone cares for her.
const ReminderCircle _noura = ReminderCircle(
  id: 'c-noura',
  name: 'أمي نورة',
  viewerId: _meId,
  viewerIsPatient: false,
  timeZone: _riyadh,
);

/// The circle of the person on this phone's own care.
const ReminderCircle _me = ReminderCircle(
  id: 'c-me',
  name: 'صحتي',
  viewerId: _meId,
  viewerIsPatient: true,
  timeZone: _riyadh,
);

/// A member going with the patient who is not the person on this phone.
const AppointmentCompanion _khaled = AppointmentCompanion(
  id: 'a-khaled',
  name: 'خالد',
);

final DoseReminderTexts _texts = DoseReminderTexts(
  title: (ReminderCircle circle, DoseOccurrence dose) => 'دواء ${circle.name}',
  body: (ReminderCircle circle, DoseOccurrence dose) => dose.name,
  measurementTitle: (ReminderCircle circle) => 'قياس ${circle.name}',
  measurementBody: (ReminderCircle circle, MeasurementOccurrence task) =>
      task.kind.name,
  appointmentTitle: (
    ReminderCircle circle,
    AppointmentLead lead,
    CareAppointment visit,
  ) => 'موعد ${circle.name} ${lead.name}',
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

/// An appointment on [day] (of November 2026) at [time] in Riyadh, by
/// default with the person on this phone going.
CareAppointment _appointment(
  int day,
  String time, {
  AppointmentStatus status = AppointmentStatus.scheduled,
  DateTime? savedAt,
  List<AppointmentCompanion> companions = const <AppointmentCompanion>[
    AppointmentCompanion(id: _meId, name: 'ريم'),
  ],
}) => CareAppointment(
  id: 'appointment-$day',
  specialty: 'القلب',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, day),
  time: time,
  place: 'مستشفى',
  remoteMethod: null,
  companions: companions,
  status: status,
  updatedAt: savedAt ?? DateTime.utc(2026, 11),
);

/// The measurement tasks of each circle.
class _Measurements extends Fake implements MeasurementRepository {
  final Map<String, List<MeasurementOccurrence>> tasks =
      <String, List<MeasurementOccurrence>>{};
  final StreamController<String> changed = StreamController<String>.broadcast();
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
  final StreamController<String> changed = StreamController<String>.broadcast();

  @override
  Stream<String> get changes => changed.stream;

  @override
  Future<List<CareAppointment>> appointments(String circleId) async =>
      visits[circleId] ?? const <CareAppointment>[];
}

/// A dose on [day] (of [month], November 2026 unless said) at [time] in
/// the patient's zone.
DoseOccurrence _dose(
  int day,
  String time, {
  String name = 'ميتفورمين',
  DoseRecord? record,
  int month = 11,
}) => DoseOccurrence(
  planId: 'plan-$name',
  scheduleId: 'schedule-$name-$time',
  scheduledOn: DateTime(2026, month, day),
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
      final PatientClock riyadh = _noura.clock;
      expect(
        doseMoment(riyadh, _dose(3, '08:30')),
        DateTime.utc(2026, 11, 3, 5, 30),
      );
      // Just after midnight in Riyadh is the day before in UTC.
      expect(
        doseMoment(riyadh, _dose(4, '01:00')),
        DateTime.utc(2026, 11, 3, 22),
      );
    });

    test('a dose keeps the wall clock of a patient in a DST zone', () {
      // London leaves summer time on 25 October 2026: 08:00 is 07:00 UTC
      // the day before and 08:00 UTC the day after.
      final PatientClock london = PatientClock('Europe/London');
      DoseOccurrence on(int day) => _dose(day, '08:00', month: 10);
      expect(doseMoment(london, on(24)), DateTime.utc(2026, 10, 24, 7));
      expect(doseMoment(london, on(26)), DateTime.utc(2026, 10, 26, 8));
    });

    test("a reminder follows the patient's zone, never the phone's", () {
      // The same 08:00 dose for Noura in Riyadh and for a patient in
      // Toronto: each is that patient's 08:00, whatever zone this phone
      // (the test machine) is in.
      const ReminderCircle toronto = ReminderCircle(
        id: 'c-toronto',
        name: 'أمي نورة',
        viewerId: _meId,
        viewerIsPatient: false,
        timeZone: 'America/Toronto',
      );
      final List<ScheduledNotification> riyadh = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[(_noura, _dose(4, '08:00'))],
        now: _now,
        texts: _texts,
      );
      final List<ScheduledNotification> abroad = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[(toronto, _dose(4, '08:00'))],
        now: _now,
        texts: _texts,
      );
      expect(riyadh.first.at, DateTime.utc(2026, 11, 4, 5));
      // A patient in Toronto: 08:00 there is 13:00 UTC.
      expect(abroad.first.at, DateTime.utc(2026, 11, 4, 13));
    });

    test('one reminder per dose to come, the nearest first, then the note', () {
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
          // Now: too close to set.
          (_noura, _dose(3, '08:00')),
        ],
        now: _now,
        texts: _texts,
      );

      expect(planned, isEmpty);
    });

    test('a medicine saved a minute before its dose is still reminded', () {
      // 07:59:20 in Riyadh, and a dose at 08:00.
      final List<ScheduledNotification> planned = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[(_noura, _dose(3, '08:00'))],
        now: _now.subtract(const Duration(seconds: 40)),
        texts: _texts,
      );

      expect(planned.first.at, _now);
      expect(planned.first.payload, isNot(keepRemindersPayload));
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

    test('the doses put off from their cards take places of reminders', () {
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
        limit: maxDoseReminders - 2,
      );

      // 58 reminders and the note; with the two snoozes, 61 of the
      // phone's 64.
      expect(planned, hasLength(59));
      expect(planned.last.payload, keepRemindersPayload);
      expect(
        planned.every((ScheduledNotification n) => n.id < cardSnoozeIdBase),
        isTrue,
      );
    });

    test('a measurement to come is reminded at its time', () {
      final List<ScheduledNotification> planned = planDoseReminders(
        measurements: <(ReminderCircle, MeasurementOccurrence)>[
          (_noura, _measurement(3, '10:00', kind: MeasurementKind.bp)),
          // Already read, skipped, or missed: nothing to remind of.
          (_noura, _measurement(3, '11:00', status: MeasurementStatus.read)),
          (_noura, _measurement(3, '12:00', status: MeasurementStatus.skipped)),
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

    test('an appointment saved today for today is said right away, once', () {
      // Saved at 08:00 in Riyadh for 15:00 the same day: its day-before
      // moment has passed.
      final CareAppointment visit = _appointment(3, '15:00', savedAt: _now);
      final List<ScheduledNotification> planned = planDoseReminders(
        appointments: <(ReminderCircle, CareAppointment)>[(_noura, visit)],
        now: _now,
        texts: _texts,
      );

      expect(planned[0].at, _now.add(appointmentSavedLead));
      expect(planned[0].title, 'موعد أمي نورة today');
      expect(planned[1].title, 'موعد أمي نورة soon');
      expect(planned, hasLength(3));

      // A later refresh does not say it again.
      final List<ScheduledNotification> later = planDoseReminders(
        appointments: <(ReminderCircle, CareAppointment)>[(_noura, visit)],
        now: _now.add(const Duration(minutes: 5)),
        texts: _texts,
      );
      expect(
        later.map((ScheduledNotification item) => item.title),
        isNot(contains('موعد أمي نورة today')),
      );
    });

    test('an appointment saved days before is not said right away', () {
      expect(
        appointmentAnnouncedAt(
          _noura.clock,
          _appointment(6, '10:00', savedAt: _now),
        ),
        isNull,
      );
      // Saved two hours and five minutes before: the two-hour one comes.
      expect(
        appointmentAnnouncedAt(
          _noura.clock,
          _appointment(3, '10:05', savedAt: _now),
        ),
        isNull,
      );
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

      expect(
        planned.map((ScheduledNotification n) => _plain(n.payload)),
        <String>[
          'measurement:c-noura',
          'appointment:c-noura',
          'appointment:c-noura',
          'dose:c-me',
          keepRemindersPayload,
        ],
      );
      expect(planned.map((ScheduledNotification n) => n.id), <int>[
        7000,
        7001,
        7002,
        7003,
        7000 + maxDoseReminders,
      ]);
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
      // And which dose it is, so its «ذكّرني لاحقًا» puts off that dose.
      expect(dose.payload.split('\u001F').sublist(3), <String>[
        doseSnoozeKey('c-me', _dose(3, '21:00')),
        'ميتفورمين',
      ]);
      expect(reminderCircleId(dose.payload), 'c-me');
      expect(reminderCircleId('$snoozeTapPrefix${dose.payload}'), 'c-me');
      final ScheduledNotification visit = planned.firstWhere(
        (ScheduledNotification n) => n.payload.startsWith('appointment:'),
      );
      expect(visit.snoozable, isFalse);
      expect(visit.payload, 'appointment:c-noura');
    });

    test('a task put off is not reminded at its own time', () {
      final DoseOccurrence dose = _dose(3, '21:00');
      final MeasurementOccurrence task = _measurement(3, '10:00');

      final List<ScheduledNotification> planned = planDoseReminders(
        doses: <(ReminderCircle, DoseOccurrence)>[(_me, dose)],
        measurements: <(ReminderCircle, MeasurementOccurrence)>[(_me, task)],
        now: _now,
        texts: _texts,
        snoozed: <String>{
          doseSnoozeKey(_me.id, dose),
          measurementSnoozeKey(_me.id, task),
        },
      );

      expect(planned, isEmpty);
    });

    test('the circle of a tapped reminder', () {
      expect(reminderCircleId('dose:c-1'), 'c-1');
      expect(reminderCircleId('measurement:c-2'), 'c-2');
      expect(reminderCircleId('appointment:c-3'), 'c-3');
      expect(reminderCircleId('dose-snooze:c-4'), 'c-4');
      expect(reminderCircleId('measurement-snooze:c-5'), 'c-5');
      expect(reminderCircleId(keepRemindersPayload), isNull);
      expect(reminderCircleId('invitation'), isNull);
      expect(isReminderPayload('measurement:c-2'), isTrue);
      expect(isReminderPayload('appointment:c-3'), isTrue);
      expect(isReminderPayload('dose-snooze:c-4'), isFalse);
      // A snooze is not one of the planned reminders, so the replace cycle
      // never cancels it.
      expect(isReminderPayload('measurement-snooze:c-5'), isFalse);
    });
  });

  group('keeping the reminders on the phone', () {
    late _Medications medications;
    late MedicationsUseCase useCase;
    late FakePhoneNotifications phone;
    late DoseReminders reminders;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
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

    test('«ذكّرني لاحقًا» in a notification puts off that same dose, as '
        'its card does', () async {
      final DoseOccurrence planned = _dose(3, '21:00');
      medications.doses[_me.id] = <DoseOccurrence>[planned];
      await reminders.sync(<ReminderCircle>[_me]);
      final ScheduledNotification dose = phone.inOrder.first;

      expect(await reminders.snoozeTap(dose.payload), isFalse);
      expect(
        await reminders.snoozeTap('$snoozeTapPrefix${dose.payload}'),
        isTrue,
      );

      final DateTime at = _now.add(notificationSnooze);
      final ScheduledNotification again = phone.scheduled[cardSnoozeIdBase]!;
      expect(again.at, at);
      expect(again.title, dose.title);
      expect(again.body, dose.body);
      expect(again.snoozable, isTrue);
      expect(reminderCircleId(again.payload), 'c-me');
      expect(again.payload, startsWith(doseSnoozePayload));
      expect(reminders.snoozes.value, <String, TaskSnooze>{
        doseSnoozeKey(_me.id, planned): TaskSnooze(
          circleId: _me.id,
          task: SnoozedTask.dose,
          subject: 'ميتفورمين',
          at: at,
        ),
      });
      // Put off before its time, its 21:00 reminder goes, and a reading
      // again does not set it back while the snooze waits.
      bool atItsTime(ScheduledNotification n) =>
          n.at == DateTime.utc(2026, 11, 3, 18);
      expect(phone.scheduled.values.where(atItsTime), isEmpty);
      await reminders.refresh();
      expect(phone.scheduled.values.where(atItsTime), isEmpty);
      expect(phone.scheduled[cardSnoozeIdBase]?.at, at);
    });

    test(
      'a measurement put off from its notification stays a measurement',
      () async {
        final MeasurementOccurrence task = _measurement(
          3,
          '10:00',
          kind: MeasurementKind.bp,
        );
        final String measurement = payloadWithText(
          '${measurementReminderPayload}c-me',
          'حان وقت القياس',
          'ضغط الدم',
          snoozeKey: measurementSnoozeKey('c-me', task),
          subject: 'bp',
        );
        expect(
          await reminders.snoozeTap('$snoozeTapPrefix$measurement'),
          isTrue,
        );
        final ScheduledNotification again = phone.scheduled[cardSnoozeIdBase]!;
        expect(again.payload, startsWith(measurementSnoozePayload));
        expect(reminderCircleId(again.payload), 'c-me');
        expect(again.title, 'حان وقت القياس');
        final TaskSnooze snooze =
            reminders.snoozes.value[measurementSnoozeKey('c-me', task)]!;
        expect(snooze.task, SnoozedTask.measurement);
        expect(snooze.subject, 'bp');
      },
    );

    test('a notification that does not say its task is not put off', () async {
      final String older = payloadWithText(
        '${doseReminderPayload}c-me',
        'حان موعد الدواء',
        'ميتفورمين',
      );

      expect(await reminders.snoozeTap('$snoozeTapPrefix$older'), isFalse);
      expect(phone.scheduled, isEmpty);
    });

    test('putting a task off asks for the permission first: it may be the '
        'only reminder this phone sets', () async {
      await reminders.snoozeDose(
        _me.id,
        _dose(3, '07:00', name: 'فيتامين د'),
        const Duration(minutes: 15),
      );

      expect(phone.permissionRequests, 1);
      final ScheduledNotification again = phone.scheduled[cardSnoozeIdBase]!;
      expect(again.at, _now.add(const Duration(minutes: 15)));
      expect(again.body, 'فيتامين د');
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

      expect(phone.inOrder.map((ScheduledNotification n) => n.at), <DateTime>[
        DateTime.utc(2026, 11, 3, 18),
        DateTime.utc(2026, 11, 3, 18, 1),
      ]);
    });

    test('a dose put off from its card comes again, and says when', () async {
      // Due an hour ago.
      final DoseOccurrence dose = _dose(3, '07:00');
      medications.doses[_me.id] = <DoseOccurrence>[dose];
      await reminders.sync(<ReminderCircle>[_me]);
      final DateTime half = _now.add(const Duration(minutes: 30));

      await reminders.snoozeDose(_me.id, dose, const Duration(minutes: 30));

      final ScheduledNotification again = phone.scheduled[cardSnoozeIdBase]!;
      expect(again.at, half);
      // The words of its own reminder, with the circle's name.
      expect(again.title, 'دواء صحتي');
      expect(again.body, 'ميتفورمين');
      expect(again.snoozable, isTrue);
      expect(again.payload, startsWith(doseSnoozePayload));
      expect(reminderCircleId(again.payload), 'c-me');
      expect(reminders.snoozes.value[doseSnoozeKey(_me.id, dose)]?.at, half);

      // A reading again leaves it: it is not one of the planned reminders.
      await reminders.refresh();
      expect(phone.scheduled[cardSnoozeIdBase]?.at, half);

      // Put off again: still one reminder, at the new time.
      await reminders.snoozeDose(_me.id, dose, const Duration(hours: 1));
      expect(
        phone.scheduled.keys.where(
          (int id) =>
              id >= cardSnoozeIdBase && id < cardSnoozeIdBase + maxCardSnoozes,
        ),
        <int>[cardSnoozeIdBase],
      );
      expect(
        reminders.snoozes.value.values.single.at,
        _now.add(const Duration(hours: 1)),
      );
    });

    test('two doses put off both come again', () async {
      final DoseOccurrence first = _dose(3, '07:00');
      final DoseOccurrence second = _dose(3, '07:30', name: 'فيتامين د');
      medications.doses[_me.id] = <DoseOccurrence>[first, second];
      await reminders.sync(<ReminderCircle>[_me]);

      for (final DoseOccurrence dose in <DoseOccurrence>[first, second]) {
        await reminders.snoozeDose(_me.id, dose, const Duration(minutes: 15));
      }

      expect(phone.scheduled[cardSnoozeIdBase]?.body, 'ميتفورمين');
      expect(phone.scheduled[cardSnoozeIdBase + 1]?.body, 'فيتامين د');
      expect(reminders.snoozes.value, hasLength(2));
    });

    test('recording a dose put off takes its reminder off', () async {
      final DoseOccurrence dose = _dose(3, '07:00');
      medications.doses[_me.id] = <DoseOccurrence>[dose];
      await reminders.sync(<ReminderCircle>[_me]);
      await reminders.snoozeDose(_me.id, dose, const Duration(minutes: 30));

      medications.doses[_me.id] = <DoseOccurrence>[
        _dose(3, '07:00', record: _taken),
      ];
      await useCase.recordDose(
        _me.id,
        dose,
        const DoseRecordDraft(outcome: DoseOutcome.taken),
      );
      await settle();
      await settle();

      expect(phone.scheduled, isNot(contains(cardSnoozeIdBase)));
      expect(reminders.snoozes.value, isEmpty);
    });

    test('a measurement put off comes again with its own words, and goes '
        'once it is read', () async {
      final _Measurements measurements = _Measurements();
      final DoseReminders both = DoseReminders(
        useCase,
        phone,
        texts: _texts,
        measurements: measurements,
        clock: () => _now,
      );
      final MeasurementOccurrence task = _measurement(3, '07:30');
      measurements.tasks[_me.id] = <MeasurementOccurrence>[task];
      await both.sync(<ReminderCircle>[_me]);

      await both.snoozeMeasurement(_me.id, task, const Duration(minutes: 15));

      final ScheduledNotification again = phone.scheduled[cardSnoozeIdBase]!;
      expect(again.title, 'قياس صحتي');
      expect(again.body, 'glucose');
      expect(again.payload, startsWith(measurementSnoozePayload));
      expect(
        both.snoozes.value[measurementSnoozeKey(_me.id, task)]?.subject,
        'glucose',
      );

      measurements.tasks[_me.id] = <MeasurementOccurrence>[
        _measurement(3, '07:30', status: MeasurementStatus.read),
      ];
      measurements.recordedNow.add(_me.id);
      await settle();
      await settle();

      expect(phone.scheduled, isNot(contains(cardSnoozeIdBase)));
      expect(both.snoozes.value, isEmpty);
    });

    test('a card still shows its time when the app opens again', () async {
      final DoseOccurrence dose = _dose(3, '07:00');
      medications.doses[_me.id] = <DoseOccurrence>[dose];
      await reminders.snoozeDose(_me.id, dose, const Duration(minutes: 30));

      final DoseReminders opened = DoseReminders(
        useCase,
        phone,
        texts: _texts,
        clock: () => _now,
      );
      await opened.sync(<ReminderCircle>[_me]);

      expect(opened.snoozes.value, <String, TaskSnooze>{
        doseSnoozeKey(_me.id, dose): TaskSnooze(
          circleId: _me.id,
          task: SnoozedTask.dose,
          subject: 'ميتفورمين',
          at: _now.add(const Duration(minutes: 30)),
        ),
      });
      expect(phone.scheduled, contains(cardSnoozeIdBase));
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
      expect(reminders.snoozes.value, isEmpty);
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
      SharedPreferences.setMockInitialValues(<String, Object>{});
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

    test('a member who does not go with the patient is not reminded of '
        'the appointment', () async {
      appointments.visits[_noura.id] = <CareAppointment>[
        _appointment(
          5,
          '16:30',
          companions: const <AppointmentCompanion>[_khaled],
        ),
      ];

      await reminders.sync(<ReminderCircle>[_noura]);

      expect(phone.scheduled, isEmpty);
    });

    test('the patient is reminded of every appointment, whoever goes with '
        'them', () async {
      appointments.visits[_me.id] = <CareAppointment>[
        _appointment(
          5,
          '16:30',
          companions: const <AppointmentCompanion>[_khaled],
        ),
      ];

      await reminders.sync(<ReminderCircle>[_me]);

      expect(
        phone.inOrder.map((ScheduledNotification n) => _plain(n.payload)),
        <String>['appointment:c-me', 'appointment:c-me', keepRemindersPayload],
      );
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

  group('a task put off, shared with the circle', () {
    late _Medications medications;
    late FakePhoneNotifications phone;
    late List<SnoozeShare> shared;
    late DoseReminders reminders;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      medications = _Medications();
      phone = FakePhoneNotifications();
      shared = <SnoozeShare>[];
      reminders = DoseReminders(
        MedicationsUseCase(medications),
        phone,
        texts: _texts,
        share: (SnoozeShare snooze) async => shared.add(snooze),
        clock: () => _now,
      );
    });

    test('putting a dose off tells the circle which dose, and for how '
        'long', () async {
      final DoseOccurrence dose = _dose(3, '07:00');

      await reminders.snoozeDose(_me.id, dose, const Duration(minutes: 15));
      await pumpEventQueue();

      expect(shared, <SnoozeShare>[
        SnoozeShare(
          circleId: _me.id,
          task: 'dose',
          taskId: dose.scheduleId,
          scheduledOn: '2026-11-03',
          minutes: 15,
        ),
      ]);
    });

    test('a reading time is told with its time', () async {
      await reminders.snoozeMeasurement(
        _me.id,
        _measurement(3, '10:00'),
        const Duration(minutes: 30),
      );
      await pumpEventQueue();

      expect(shared.single.toJson(), <String, Object>{
        'task': 'measurement',
        'task_id': 'version-glucose',
        'scheduled_on': '2026-11-03',
        'time_of_day': '10:00',
        'minutes': 30,
      });
    });

    test('offline, this phone still reminds of it', () async {
      reminders = DoseReminders(
        MedicationsUseCase(medications),
        phone,
        texts: _texts,
        share: (SnoozeShare _) async => throw Exception('offline'),
        clock: () => _now,
      );

      await reminders.snoozeDose(
        _me.id,
        _dose(3, '07:00'),
        const Duration(minutes: 15),
      );
      await pumpEventQueue();

      expect(
        phone.scheduled[cardSnoozeIdBase]?.at,
        _now.add(const Duration(minutes: 15)),
      );
    });

    test('a dose someone else put off is not reminded of at its own time: '
        'the server reminds at the new one', () async {
      final SharedSnooze byReem = SharedSnooze(
        remindAt: DateTime.utc(2026, 11, 3, 18, 30),
        minutes: 30,
        byName: 'ريم',
      );
      medications.doses[_noura.id] = <DoseOccurrence>[
        _dose(3, '21:00').withSnooze(byReem),
        _dose(3, '22:00', name: 'فيتامين د'),
      ];

      await reminders.sync(<ReminderCircle>[_noura]);

      // 22:00 in Riyadh is 19:00 UTC; the note comes a minute after it.
      expect(phone.inOrder.map((ScheduledNotification n) => n.at), <DateTime>[
        DateTime.utc(2026, 11, 3, 19),
        DateTime.utc(2026, 11, 3, 19, 1),
      ]);
    });

    test("the server's snooze reads with who put it off", () {
      final SharedSnooze? snooze = SharedSnooze.fromJson(<String, dynamic>{
        'remind_at': '2026-11-03T05:20:00+00:00',
        'minutes': 15,
        'snoozed_by': <String, dynamic>{
          'account_id': 'a-reem',
          'name': 'ريم',
          'avatar_code': null,
        },
      });

      expect(snooze?.remindAt, DateTime.utc(2026, 11, 3, 5, 20));
      expect(snooze?.byName, 'ريم');
      expect(snooze?.waitsAt(DateTime.utc(2026, 11, 3, 5, 19)), isTrue);
      expect(snooze?.waitsAt(DateTime.utc(2026, 11, 3, 5, 20)), isFalse);
      expect(SharedSnooze.fromJson(null), isNull);
    });

    test('a key of another shape is told nothing', () {
      expect(snoozeShareOf('c-me|odd', const Duration(minutes: 15)), isNull);
    });
  });
}
