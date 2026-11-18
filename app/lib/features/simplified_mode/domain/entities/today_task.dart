import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task_kind.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task_props.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task_status.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/simplified_mode/domain/entities/today_task_kind.dart';
export 'package:app/features/simplified_mode/domain/entities/today_task_snooze_key.dart';
export 'package:app/features/simplified_mode/domain/entities/today_task_status.dart';

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
