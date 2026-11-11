import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/home/presentation/today_snapshot.dart';
import 'package:app/features/home/presentation/widgets/today_prayer_period.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's city and the day's rows under each prayer period.
class TodayPrayerPeriods extends StatelessWidget {
  const TodayPrayerPeriods({
    super.key,
    required this.snapshot,
    required this.day,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final PrayerDay day;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetText(
          context.tr('prayer_times.city', args: <String>[day.city]),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < Prayer.values.length; index++) ...<Widget>[
          _period(index, day),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _period(int index, PrayerDay day) => TodayPrayerPeriod(
    prayer: Prayer.values[index],
    time: day.times[Prayer.values[index]]!,
    nextTime: index + 1 < Prayer.values.length
        ? day.times[Prayer.values[index + 1]]
        : null,
    prayerTimes: day.times,
    occurrences: snapshot.medications.todayOccurrences,
    measurementTasks: snapshot.todayMeasurements,
    appointments: snapshot.todayAppointments,
    circleId: circleId,
    canManage: canManage,
    now: snapshot.now,
  );
}
