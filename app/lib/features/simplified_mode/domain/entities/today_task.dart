import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
import 'package:equatable/equatable.dart';

/// One dose, measurement or appointment of today, with exactly one of
/// [dose], [measurement] and [appointment] set, matching [kind].
class TodayTask extends Equatable {
  const TodayTask._({
    required this.kind,
    required this.day,
    required this.time,
    required this.status,
    this.dose,
    this.measurement,
    this.appointment,
  });

  TodayTask.medication(DoseOccurrence value, TodayTaskStatus status)
    : this._(
        kind: TodayTaskKind.medication,
        day: value.scheduledOn,
        time: value.time,
        status: status,
        dose: value,
      );

  TodayTask.measurement(MeasurementOccurrence value, TodayTaskStatus status)
    : this._(
        kind: TodayTaskKind.measurement,
        day: value.scheduledOn,
        time: value.time,
        status: status,
        measurement: value,
      );

  TodayTask.appointment(CareAppointment value, TodayTaskStatus status)
    : this._(
        kind: TodayTaskKind.appointment,
        day: value.scheduledOn,
        time: value.time,
        status: status,
        appointment: value,
      );

  final TodayTaskKind kind;
  final DateTime day;

  /// The patient's wall time, «HH:mm».
  final String time;
  final TodayTaskStatus status;
  final DoseOccurrence? dose;
  final MeasurementOccurrence? measurement;
  final CareAppointment? appointment;

  /// The task's wall time, on the scale of [PatientClock.now].
  DateTime get scheduledAt => wallClockAt(day, time);

  TodayTask withStatus(TodayTaskStatus value) => TodayTask._(
    kind: kind,
    day: day,
    time: time,
    status: value,
    dose: dose,
    measurement: measurement,
    appointment: appointment,
  );

  @override
  List<Object?> get props => todayTaskProps(this);
}

/// What a task of the day is.
enum TodayTaskKind { medication, measurement, appointment }

/// Where a task stands now, as the simplified mode words it: «تم»,
/// «التالي», «فات موعده», «لاحقًا».
enum TodayTaskStatus { done, next, late, later }

/// What makes two [TodayTask]s equal: every field, in the order the
/// class declares them.
List<Object?> todayTaskProps(TodayTask task) => <Object?>[
  task.kind,
  task.day,
  task.time,
  task.status,
  task.dose,
  task.measurement,
  task.appointment,
];

/// Where [dose] stands at the patient's wall time [wall].
TodayTaskStatus todayDoseStatus(DoseOccurrence dose, DateTime wall) {
  if (dose.record != null) return TodayTaskStatus.done;
  return switch (medicationTimingState(dose, wall)) {
    DoseTimingState.late || DoseTimingState.missed => TodayTaskStatus.late,
    _ => TodayTaskStatus.later,
  };
}

/// The server's status is read once; the deadline it sends keeps the
/// status right after that.
TodayTaskStatus todayMeasurementStatus(
  MeasurementOccurrence item,
  DateTime now,
) {
  if (item.record != null) return TodayTaskStatus.done;
  if (now.isAfter(item.deadlineAt)) return TodayTaskStatus.late;
  return TodayTaskStatus.later;
}

/// A visit is done once «حضرت» is said; one whose time came waits for it.
TodayTaskStatus todayAppointmentStatus(CareAppointment item, DateTime wall) {
  if (item.status == AppointmentStatus.completed) return TodayTaskStatus.done;
  return item.scheduledAt.isAfter(wall)
      ? TodayTaskStatus.later
      : TodayTaskStatus.late;
}

/// Time order; at the same time, doses before measurements before visits.
int todayTaskOrder(TodayTask a, TodayTask b) {
  final int byTime = a.scheduledAt.compareTo(b.scheduledAt);
  return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
}

/// Whether [a] and [b] fall on the same calendar date.
bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Tomorrow's first dose not yet recorded, for «أول دواء غدًا ...»; null
/// when none.
DoseOccurrence? firstDoseOn(List<DoseOccurrence> doses, DateTime tomorrow) {
  final List<DoseOccurrence> tomorrowDoses = <DoseOccurrence>[
    for (final DoseOccurrence dose in doses)
      if (isSameDate(dose.scheduledOn, tomorrow) && dose.record == null) dose,
  ]..sort((a, b) => a.time.compareTo(b.time));
  return tomorrowDoses.firstOrNull;
}

/// The nearest scheduled appointment after the wall time [wall], on any
/// day; null when none.
CareAppointment? nextAppointment(
  List<CareAppointment> appointments,
  DateTime wall,
) {
  final List<CareAppointment> coming = <CareAppointment>[
    for (final CareAppointment item in appointments)
      if (item.status == AppointmentStatus.scheduled &&
          item.scheduledAt.isAfter(wall))
        item,
  ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return coming.firstOrNull;
}

/// The key a task is put off by, shared with the detailed mode.
extension TodayTaskSnoozeKey on TodayTask {
  /// The key its «ذكّرني لاحقًا» is kept by in [circleId], the same as
  /// the detailed mode's ([DoseReminders.snoozes]); null for an
  /// appointment, which is not put off.
  String? snoozeKey(String circleId) => switch ((dose, measurement)) {
    (final DoseOccurrence value, _) => doseSnoozeKey(circleId, value),
    (_, final MeasurementOccurrence value) => measurementSnoozeKey(
      circleId,
      value,
    ),
    _ => null,
  };
}
