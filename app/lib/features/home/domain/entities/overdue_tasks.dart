import 'package:app/core/utils/overdue_window.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/home/domain/entities/day_task_times.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// The tasks of the overdue days that «اليوم» still lets the person answer,
/// all counted from the patient's [today].
abstract final class OverdueTasks {
  /// The measurements nobody recorded, from the first overdue day to today.
  static List<MeasurementOccurrence> measurements(
    List<MeasurementOccurrence> tasks,
    DateTime today,
  ) =>
      tasks
          .where(
            (task) =>
                task.status == MeasurementStatus.missed &&
                _inWindow(task.scheduledOn, today),
          )
          .toList()
        // The oldest first, as «يحتاج انتباهك» reads.
        ..sort((a, b) {
          final int byDay = a.scheduledOn.compareTo(b.scheduledOn);
          return byDay != 0 ? byDay : a.time.compareTo(b.time);
        });

  /// The appointments nobody closed: of the days before today, and today's
  /// that another task of the day ([doses], [measurements], the visits)
  /// came after by [now]; until then one stays on «اليوم»'s top card.
  static List<CareAppointment> appointments(
    List<CareAppointment> items,
    DateTime today, {
    DateTime? now,
    Iterable<DoseOccurrence> doses = const <DoseOccurrence>[],
    Iterable<MeasurementOccurrence> measurements =
        const <MeasurementOccurrence>[],
  }) {
    final List<DateTime> times = dayTaskTimes(
      today,
      doses: doses,
      measurements: measurements,
      visits: items,
    );
    bool overtaken(CareAppointment item) =>
        now != null &&
        item.scheduledAt.isBefore(now) &&
        item.overtakenAt(now, times);
    return items
        .where(
          (item) =>
              // «فائت» chosen from «السجل» is an answer already.
              item.isOpen &&
              _inWindow(item.scheduledOn, today) &&
              (scheduleDay(item.scheduledOn).isBefore(scheduleDay(today)) ||
                  overtaken(item)),
        )
        .toList()
      // The oldest first, as «يحتاج انتباهك» reads.
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  static bool _inWindow(DateTime day, DateTime today) {
    final DateTime scheduled = scheduleDay(day);
    return !scheduled.isBefore(overdueStart(today)) &&
        !scheduled.isAfter(scheduleDay(today));
  }
}
