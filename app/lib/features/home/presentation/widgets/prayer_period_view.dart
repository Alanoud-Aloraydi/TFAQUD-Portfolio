import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/features/home/presentation/widgets/period_task_rows.dart';
import 'package:app/features/home/presentation/widgets/prayer_period_tile.dart';
import 'package:app/features/home/presentation/widgets/prayer_period_title.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// One prayer period as a card: its title and the [rows] opened under it.
class PrayerPeriodView extends StatelessWidget {
  const PrayerPeriodView({
    super.key,
    required this.prayer,
    required this.time,
    required this.current,
    required this.open,
    required this.rows,
    required this.circleId,
    required this.canManage,
    required this.now,
  });

  final Prayer prayer;
  final String time;
  final bool current;
  final bool open;
  final List<PeriodEntry> rows;
  final String circleId;
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) => PrayerPeriodCard(
    current: current,
    child: PrayerPeriodTile(
      // A new day or a changed open state rebuilds the tile closed or open.
      key: ValueKey('${now.year}-${now.month}-${now.day}:${prayer.name}:$open'),
      icon: prayerIcon(prayer),
      current: current,
      expanded: open && rows.isNotEmpty,
      title: PrayerPeriodTitle(
        name: context.tr('prayer_times.${prayer.name}'),
        time: clockText(time),
        current: current,
        taskCount: rows.length,
      ),
      children: periodTaskRows(
        rows,
        circleId: circleId,
        canManage: canManage,
        now: now,
      ),
    ),
  );
}

IconData prayerIcon(Prayer prayer) => switch (prayer) {
  Prayer.fajr => TafaqodPhosphorIcons.sunHorizon,
  Prayer.dhuhr => TafaqodPhosphorIcons.sun,
  Prayer.asr => TafaqodPhosphorIcons.sunDim,
  // Phosphor's sun-horizon glyph is left-right symmetric, so mirroring it
  // for Maghrib looked identical to Fajr. Maghrib is still about the sun
  // (not the moon, which is Isha), so a fading/clouded sun shape instead.
  Prayer.maghrib => TafaqodPhosphorIcons.cloudSun,
  Prayer.isha => TafaqodPhosphorIcons.moonStars,
};

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
