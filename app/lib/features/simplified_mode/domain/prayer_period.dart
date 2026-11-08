import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

/// The part of the day a task falls in, named after the prayer before it
/// («بعد المغرب»): the way the simplified mode tells the time of a task.
enum PrayerPeriod {
  beforeFajr,
  afterFajr,
  afterDhuhr,
  afterAsr,
  afterMaghrib,
  afterIsha,
}

/// The period of [time] («HH:mm») on [day]: after the last prayer at or
/// before it, or before Fajr.
PrayerPeriod prayerPeriodOf(String time, PrayerDay day) {
  final int minute = _minutes(time);
  PrayerPeriod result = PrayerPeriod.beforeFajr;
  for (int index = 0; index < Prayer.values.length; index++) {
    final String? prayerTime = day.times[Prayer.values[index]];
    if (prayerTime != null && minute >= _minutes(prayerTime)) {
      result = PrayerPeriod.values[index + 1];
    }
  }
  return result;
}

/// [tasks] (in time order) in runs of one period each. Without prayer
/// times ([day] null) they stay one run with no period.
List<(PrayerPeriod?, List<TodayTask>)> groupByPeriod(
  List<TodayTask> tasks,
  PrayerDay? day,
) {
  final List<(PrayerPeriod?, List<TodayTask>)> groups =
      <(PrayerPeriod?, List<TodayTask>)>[];
  for (final TodayTask task in tasks) {
    final PrayerPeriod? period = day == null
        ? null
        : prayerPeriodOf(task.time, day);
    if (groups.isNotEmpty && groups.last.$1 == period) {
      groups.last.$2.add(task);
    } else {
      groups.add((period, <TodayTask>[task]));
    }
  }
  return groups;
}

int _minutes(String time) {
  final List<String> parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
