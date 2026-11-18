import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/today_schedule_ahead.dart';
import 'package:app/features/simplified_mode/domain/today_task_statuses.dart';

export 'package:app/features/simplified_mode/domain/home_focus.dart';
export 'package:app/features/simplified_mode/domain/today_schedule_focus.dart';
export 'package:app/features/simplified_mode/domain/today_schedule_recording.dart';

/// Today's doses, measurements and appointments in time order, each with
/// its status at one moment. Statuses are worked out here from the times,
/// not taken from the server's reading, so the screen stays right as the
/// minutes pass without reading the server again.
class TodaySchedule {
  TodaySchedule._({
    required List<TodayTask> tasks,
    required this.firstDoseTomorrow,
    required this.upcomingAppointment,
    required this.wallNow,
  }) : tasks = List<TodayTask>.unmodifiable(tasks);

  /// [now] is an instant, read on the patient's [clock]; [doses] may
  /// include tomorrow's (for [firstDoseTomorrow]); [appointments] may be of
  /// any day.
  factory TodaySchedule.build({
    required PatientClock clock,
    required DateTime now,
    required List<DoseOccurrence> doses,
    required List<MeasurementOccurrence> measurements,
    required List<CareAppointment> appointments,
  }) {
    final DateTime wall = clock.wallTime(now);
    final DateTime today = scheduleDay(wall);
    final List<TodayTask> raw = <TodayTask>[
      for (final DoseOccurrence dose in doses)
        if (isSameDate(dose.scheduledOn, today))
          TodayTask.medication(dose, todayDoseStatus(dose, wall)),
      // A measurement nobody recorded leaves once the next one of its kind
      // is due: a reading now would be the same value, for that one.
      for (final MeasurementOccurrence item in measurements)
        if (isSameDate(item.scheduledOn, today) &&
            (item.record != null || !item.supersededAt(wall)))
          TodayTask.measurement(item, todayMeasurementStatus(item, now)),
      for (final CareAppointment item in appointments)
        if (isSameDate(item.scheduledOn, today) &&
            item.status != AppointmentStatus.cancelled)
          TodayTask.appointment(item, todayAppointmentStatus(item, wall)),
    ]..sort(todayTaskOrder);

    // The first task still to come is «التالي»; the rest wait «لاحقًا».
    final List<TodayTask> tasks = List<TodayTask>.of(raw);
    final int next = tasks.indexWhere(
      (task) => task.status == TodayTaskStatus.later,
    );
    if (next != -1) tasks[next] = tasks[next].withStatus(TodayTaskStatus.next);

    return TodaySchedule._(
      tasks: tasks,
      firstDoseTomorrow: firstDoseOn(doses, addDays(today, 1)),
      upcomingAppointment: nextAppointment(appointments, wall),
      wallNow: wall,
    );
  }

  final List<TodayTask> tasks;

  /// Tomorrow's first dose, for «أول دواء غدًا ...»; null when none.
  final DoseOccurrence? firstDoseTomorrow;

  /// The nearest scheduled appointment still to come, on any day: what an
  /// appointment reminder is about.
  final CareAppointment? upcomingAppointment;

  /// The patient's wall time the statuses were worked out at.
  final DateTime wallNow;
}
