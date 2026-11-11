import 'package:app/features/home/presentation/today_snapshot.dart';
import 'package:app/features/home/presentation/widgets/today_fallback_rows.dart';
import 'package:app/features/home/presentation/widgets/today_prayer_periods.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:flutter/material.dart';

/// The day's rows under each prayer period, or in time order while the
/// prayer times are not available ([day] null).
class TodaySchedule extends StatelessWidget {
  const TodaySchedule({
    super.key,
    required this.snapshot,
    required this.day,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final PrayerDay? day;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final PrayerDay? day = this.day;
    if (day == null) {
      return TodayFallbackRows(
        doses: snapshot.medications.todayOccurrences,
        measurements: snapshot.todayMeasurements,
        appointments: snapshot.todayAppointments,
        circleId: circleId,
        canManage: canManage,
        now: snapshot.now,
      );
    }
    return TodayPrayerPeriods(
      snapshot: snapshot,
      day: day,
      circleId: circleId,
      canManage: canManage,
    );
  }
}
