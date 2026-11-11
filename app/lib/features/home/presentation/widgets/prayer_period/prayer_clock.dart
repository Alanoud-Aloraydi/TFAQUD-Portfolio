import 'package:app/features/prayer_times/domain/prayer_day.dart';

const int _minutesPerHour = 60;
const int _minutesPerDay = 24 * _minutesPerHour;

/// Minutes since midnight of an "HH:mm" clock string.
int minutesOfDay(String time) {
  final List<String> parts = time.split(':');
  return int.parse(parts[0]) * _minutesPerHour + int.parse(parts[1]);
}

/// Whether [now] is inside the period that starts at [start] and ends at
/// [end]; the last period of the day has no [end].
bool isInPeriod(DateTime now, String start, String? end) {
  final int minute = now.hour * _minutesPerHour + now.minute;
  final int endMinute = end == null ? _minutesPerDay : minutesOfDay(end);
  return minute >= minutesOfDay(start) && minute < endMinute;
}

/// The prayer whose time is closest to [time].
Prayer nearestPrayer(String time, Map<Prayer, String> prayerTimes) {
  final int target = minutesOfDay(time);
  int distance(Prayer prayer) =>
      (minutesOfDay(prayerTimes[prayer]!) - target).abs();
  return Prayer.values.reduce(
    (best, item) => distance(item) < distance(best) ? item : best,
  );
}
