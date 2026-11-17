import 'package:app/core/utils/overdue_window.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment.dart';

/// How long before its time a visit can be marked «حضرت», as the server
/// allows (ATTEND_EARLY).
const Duration attendEarly = Duration(hours: 1);

/// When «حضرت» opens and closes for a visit. It opens [attendEarly] before
/// its time and stays open while «يحتاج انتباهك» lists the visit (its day
/// not older than [overdueDays]); after that the visit is missed, as the
/// server holds it (ATTEND_DAYS_AFTER).
extension AppointmentAttendWindow on CareAppointment {
  /// The moment «حضرت» opens, on the scale of the patient clock.
  DateTime get attendOpensAt => scheduledAt.subtract(attendEarly);

  /// Whether a still open visit can be marked attended at [now] on the
  /// patient's [today].
  bool canAttendAt(DateTime now, DateTime today) =>
      status == AppointmentStatus.scheduled &&
      !attendOpensAt.isAfter(now) &&
      !isMissedOn(today);

  /// Whether nobody answered it before it left «يحتاج انتباهك».
  bool isMissedOn(DateTime today) =>
      status == AppointmentStatus.scheduled &&
      scheduleDay(scheduledOn).isBefore(overdueStart(today));

  /// Whether another task of the day ([taskTimes], wall times) came after
  /// this visit by [now]. Until one does, a visit past its time stays on
  /// «اليوم»'s top card; from then it waits in «يحتاج انتباهك».
  bool overtakenAt(DateTime now, Iterable<DateTime> taskTimes) => taskTimes.any(
    (DateTime time) => time.isAfter(scheduledAt) && !time.isAfter(now),
  );
}
