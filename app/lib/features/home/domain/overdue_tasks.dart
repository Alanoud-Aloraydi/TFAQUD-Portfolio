import 'package:app/core/utils/overdue_window.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// The tasks of the overdue days that «اليوم» still lets the person answer,
/// all counted from the patient's [today].
abstract final class OverdueTasks {
  /// The measurements nobody recorded, from the first overdue day to today.
  static List<MeasurementOccurrence> measurements(
    List<MeasurementOccurrence> tasks,
    DateTime today,
  ) => tasks
      .where(
        (task) =>
            task.status == MeasurementStatus.missed &&
            _inWindow(task.scheduledOn, today),
      )
      .toList();

  /// The appointments of the days before today that nobody closed. Today's
  /// own wait for confirmation in the day's schedule.
  static List<CareAppointment> appointments(
    List<CareAppointment> items,
    DateTime today,
  ) =>
      items
          .where(
            (item) =>
                item.status == AppointmentStatus.scheduled &&
                _inWindow(item.scheduledOn, today) &&
                scheduleDay(item.scheduledOn).isBefore(scheduleDay(today)),
          )
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  static bool _inWindow(DateTime day, DateTime today) {
    final DateTime scheduled = scheduleDay(day);
    return !scheduled.isBefore(overdueStart(today)) &&
        !scheduled.isAfter(scheduleDay(today));
  }
}
