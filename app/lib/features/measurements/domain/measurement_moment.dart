import 'package:app/core/utils/patient_clock.dart';

import 'package:app/core/utils/schedule_day.dart';

/// The latest moment, not after now on [clock], whose patient wall time is
/// [time] («HH:mm»): today's, or yesterday's while today's is still to
/// come. A reading can only be in the past, so «11:50 م» picked at 12:10
/// after midnight is last night's; the server accepts it for that task.
DateTime latestReadingMoment(PatientClock clock, String time) {
  final DateTime today = clock.today();
  final DateTime moment = clock.momentOf(today, time);
  return clock.wallTime(moment).isAfter(clock.now())
      ? clock.momentOf(addDays(today, -1), time)
      : moment;
}
