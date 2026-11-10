import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

/// 12:00 in Riyadh on 9 November 2026.
final DateTime _noon = DateTime.utc(2026, 11, 9, 9);
final DateTime _today = DateTime(2026, 11, 9);
final DateTime _tomorrow = DateTime(2026, 11, 10);

DoseOccurrence _dose(
  String time, {
  DateTime? day,
  bool taken = false,
  String schedule = 's',
}) => DoseOccurrence(
  planId: 'plan-$time',
  scheduleId: '$schedule-$time',
  scheduledOn: day ?? _today,
  time: time,
  name: 'ميتفورمين',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  missedAfterMinutes: 60,
  record: taken
      ? DoseRecord(
          id: 'r-$time',
          outcome: DoseOutcome.taken,
          recordedAt: _noon,
          takenAt: _noon,
        )
      : null,
);

/// A task at [time] (Riyadh) with an hour to record it.
MeasurementOccurrence _measurement(String time, {bool read = false}) {
  final int hour = int.parse(time.split(':')[0]);
  return MeasurementOccurrence(
    planId: 'm',
    versionId: 'v',
    kind: MeasurementKind.bp,
    scheduledOn: _today,
    time: time,
    deadlineAt: DateTime.utc(2026, 11, 9, hour - 3 + 1),
    status: MeasurementStatus.upcoming,
    record: read
        ? MeasurementReading(
            id: 'm-r',
            kind: MeasurementKind.bp,
            outcome: 'read',
            recordedAt: _noon,
          )
        : null,
  );
}

CareAppointment _appointment(
  String time, {
  DateTime? day,
  AppointmentStatus status = AppointmentStatus.scheduled,
}) => CareAppointment(
  id: 'a-$time',
  specialty: 'diabetes',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: day ?? _today,
  time: time,
  place: null,
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: status,
  updatedAt: _noon,
);

TodaySchedule _build({
  List<DoseOccurrence> doses = const <DoseOccurrence>[],
  List<MeasurementOccurrence> measurements = const <MeasurementOccurrence>[],
  List<CareAppointment> appointments = const <CareAppointment>[],
  DateTime? now,
  String zone = 'Asia/Riyadh',
}) => TodaySchedule.build(
  clock: PatientClock(zone),
  now: now ?? _noon,
  doses: doses,
  measurements: measurements,
  appointments: appointments,
);

void main() {
  group('SimplifiedTodaySchedule', () {
    group('today schedule', () {
      test('statuses: done, late, the first to come is next, then later', () {
        final schedule = _build(
          doses: [
            _dose('08:00', taken: true),
            _dose('10:00'),
            _dose('18:00'),
            _dose('21:00'),
          ],
        );
        expect(schedule.tasks.map((task) => task.status), [
          TodayTaskStatus.done,
          TodayTaskStatus.late,
          TodayTaskStatus.next,
          TodayTaskStatus.later,
        ]);
        expect(schedule.doneCount, 1);
        expect(schedule.total, 4);
      });

      test("the day and statuses are the patient's, in their own zone", () {
        // 09:00 UTC is 12:00 in Riyadh but 04:00 in Toronto: a patient there
        // has the 10:00 dose still to come, not late.
        final schedule = _build(
          doses: [_dose('10:00')],
          zone: 'America/Toronto',
        );
        expect(schedule.tasks.single.status, TodayTaskStatus.next);
        // 03:00 UTC on the 10th is still the 9th in Toronto (22:00).
        final evening = _build(
          doses: [
            _dose('21:00'),
            _dose('08:00', day: _tomorrow),
          ],
          zone: 'America/Toronto',
          now: DateTime.utc(2026, 11, 10, 3),
        );
        expect(evening.tasks.single.time, '21:00');
        expect(evening.firstDoseTomorrow?.time, '08:00');
      });

      test('a dose within its first quarter hour is still the next one', () {
        final schedule = _build(doses: [_dose('11:50')]);
        expect(schedule.tasks.single.status, TodayTaskStatus.next);
        expect(schedule.focus, HomeFocus.task);
      });

      test('kinds mix in time order; cancelled appointments are left out', () {
        final schedule = _build(
          doses: [_dose('18:00')],
          measurements: [_measurement('14:00')],
          appointments: [
            _appointment('13:00'),
            _appointment('15:00', status: AppointmentStatus.cancelled),
          ],
        );
        expect(schedule.tasks.map((task) => task.kind), [
          TodayTaskKind.appointment,
          TodayTaskKind.measurement,
          TodayTaskKind.medication,
        ]);
      });

      test('an appointment whose time came is done; no recording needed', () {
        final schedule = _build(appointments: [_appointment('11:00')]);
        expect(schedule.tasks.single.status, TodayTaskStatus.done);
        expect(schedule.focus, HomeFocus.allDone);
      });

      test('a measurement past its deadline is late', () {
        final schedule = _build(measurements: [_measurement('09:00')]);
        expect(schedule.tasks.single.status, TodayTaskStatus.late);
      });

      test(
        'tomorrow\'s doses are not today\'s, but give the first of tomorrow',
        () {
          final schedule = _build(
            doses: [
              _dose('08:00', taken: true),
              _dose('09:00', day: _tomorrow),
              _dose('07:00', day: _tomorrow),
            ],
          );
          expect(schedule.total, 1);
          expect(schedule.firstDoseTomorrow?.time, '07:00');
        },
      );

      test('the nearest scheduled appointment to come, on any day', () {
        final schedule = _build(
          appointments: [
            _appointment('10:30', day: _tomorrow),
            _appointment('09:00'),
            _appointment('16:00', status: AppointmentStatus.cancelled),
          ],
        );
        expect(schedule.upcomingAppointment?.scheduledOn, _tomorrow);
      });
    });

    group('the home card', () {
      test('a late dose comes first, even with a next task', () {
        final schedule = _build(
          doses: [_dose('09:00'), _dose('10:00'), _dose('18:00')],
        );
        expect(schedule.focus, HomeFocus.lateDose);
        // The most recent late dose, not the oldest.
        expect(schedule.focusTask?.time, '10:00');
      });

      test('a late measurement shows when nothing else is coming', () {
        final schedule = _build(
          doses: [_dose('08:00', taken: true)],
          measurements: [_measurement('09:00')],
        );
        expect(schedule.focus, HomeFocus.task);
        expect(schedule.focusTask?.kind, TodayTaskKind.measurement);
      });

      test('all done only when every task is resolved', () {
        expect(
          _build(doses: [_dose('08:00', taken: true)]).focus,
          HomeFocus.allDone,
        );
        expect(_build().focus, HomeFocus.empty);
      });
    });

    group('what a reminder asks about', () {
      test('the most recent dose whose time came', () {
        final schedule = _build(
          doses: [_dose('09:00'), _dose('11:30'), _dose('18:00')],
        );
        expect(schedule.taskToRecord(TodayTaskKind.medication)?.time, '11:30');
      });

      test(
        'the next dose when it can already be recorded (within an hour)',
        () {
          final schedule = _build(doses: [_dose('12:40')]);
          expect(
            schedule.taskToRecord(TodayTaskKind.medication)?.time,
            '12:40',
          );
        },
      );

      test('nothing when the next is more than an hour away', () {
        final schedule = _build(
          doses: [_dose('08:00', taken: true), _dose('18:00')],
        );
        expect(schedule.taskToRecord(TodayTaskKind.medication), isNull);
      });

      test('a recorded measurement is not asked again', () {
        final schedule = _build(
          measurements: [_measurement('11:00', read: true)],
        );
        expect(schedule.taskToRecord(TodayTaskKind.measurement), isNull);
      });
    });

    group('prayer periods', () {
      final PrayerDay day = PrayerDay(
        date: _today,
        city: 'الرياض',
        times: const <Prayer, String>{
          Prayer.fajr: '04:50',
          Prayer.dhuhr: '11:40',
          Prayer.asr: '14:50',
          Prayer.maghrib: '17:15',
          Prayer.isha: '18:45',
        },
      );

      test('a time falls after the last prayer before it', () {
        expect(prayerPeriodOf('03:00', day), PrayerPeriod.beforeFajr);
        expect(prayerPeriodOf('04:50', day), PrayerPeriod.afterFajr);
        expect(prayerPeriodOf('11:39', day), PrayerPeriod.afterFajr);
        expect(prayerPeriodOf('12:00', day), PrayerPeriod.afterDhuhr);
        expect(prayerPeriodOf('18:00', day), PrayerPeriod.afterMaghrib);
        expect(prayerPeriodOf('21:00', day), PrayerPeriod.afterIsha);
      });

      test('tasks group in runs of one period; none without prayer times', () {
        final tasks = _build(
          doses: [_dose('08:00'), _dose('09:00'), _dose('18:00')],
          now: DateTime.utc(2026, 11, 9, 3),
        ).tasks;
        final groups = groupByPeriod(tasks, day);
        expect(groups.map((group) => group.$1), [
          PrayerPeriod.afterFajr,
          PrayerPeriod.afterMaghrib,
        ]);
        expect(groups.first.$2, hasLength(2));
        expect(groupByPeriod(tasks, null).single.$1, isNull);
      });
    });

    test('a tapped reminder says which kind of task it is about', () {
      ReminderRequest? request(String payload) => reminderRequest(payload);
      expect(
        request('dose:c'),
        const ReminderRequest(TodayTaskKind.medication),
      );
      expect(request('dose-snooze:c')?.kind, TodayTaskKind.medication);
      expect(request('measurement:c')?.kind, TodayTaskKind.measurement);
      expect(request('measurement-snooze:c')?.kind, TodayTaskKind.measurement);
      expect(request('appointment:c')?.kind, TodayTaskKind.appointment);
      expect(request('reminders:keep'), isNull);
      expect(request('dose:'), isNull);
    });

    test('a reminder carries which dose it is about', () {
      final DoseOccurrence dose = _dose('09:00');
      final String payload = payloadWithText(
        'dose:c',
        'title',
        'body',
        snoozeKey: doseSnoozeKey('c', dose),
        subject: dose.name,
      );
      expect(
        reminderRequest(payload),
        ReminderRequest(
          TodayTaskKind.medication,
          taskKey: doseSnoozeKey('c', dose),
        ),
      );
    });

    group('the exact task a reminder asks about', () {
      test('the dose it was opened for, not the most recent one due', () {
        final schedule = _build(doses: [_dose('09:00'), _dose('11:30')]);
        final TodayTask chosen = schedule.tasks.first;
        expect(
          schedule.reminderTask(ReminderRequest.of(chosen, 'c'), 'c')?.time,
          '09:00',
        );
      });

      test('nothing once that dose was recorded', () {
        final schedule = _build(
          doses: [_dose('09:00', taken: true), _dose('11:30')],
        );
        final ReminderRequest request = ReminderRequest(
          TodayTaskKind.medication,
          taskKey: doseSnoozeKey('c', _dose('09:00')),
        );
        expect(schedule.reminderTask(request, 'c'), isNull);
      });

      test("nothing for another circle's reminder", () {
        final schedule = _build(doses: [_dose('11:30')]);
        final ReminderRequest request = ReminderRequest(
          TodayTaskKind.medication,
          taskKey: doseSnoozeKey('other', _dose('11:30')),
        );
        expect(schedule.reminderTask(request, 'c'), isNull);
      });

      test('without a key, the one of its kind due now', () {
        final schedule = _build(doses: [_dose('09:00'), _dose('11:30')]);
        expect(
          schedule
              .reminderTask(
                const ReminderRequest(TodayTaskKind.medication),
                'c',
              )
              ?.time,
          '11:30',
        );
      });
    });

    group('a typed reading', () {
      test('blood pressure needs the upper number above the lower', () {
        const SimplifiedReading valid = SimplifiedReading(
          kind: MeasurementKind.bp,
          valueOne: 127,
          valueTwo: 80,
        );
        expect(valid.isValid, isTrue);
        expect(
          const SimplifiedReading(
            kind: MeasurementKind.bp,
            valueOne: 80,
            valueTwo: 127,
          ).isValid,
          isFalse,
        );
        expect(
          const SimplifiedReading(
            kind: MeasurementKind.bp,
            valueOne: 127,
          ).isValid,
          isFalse,
        );
      });

      test('values stay between 1 and 999; glucose has one', () {
        expect(
          const SimplifiedReading(
            kind: MeasurementKind.glucose,
            valueOne: 112,
          ).isValid,
          isTrue,
        );
        expect(
          const SimplifiedReading(
            kind: MeasurementKind.glucose,
            valueOne: 0,
          ).isValid,
          isFalse,
        );
        expect(
          const SimplifiedReading(
            kind: MeasurementKind.glucose,
            valueOne: 112,
            valueTwo: 80,
          ).isValid,
          isFalse,
        );
      });
    });
  });
}
