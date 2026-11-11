import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entries.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_open_rule.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/photo_probe.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_clock.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_period_view.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:flutter/material.dart';

/// One prayer period of «اليوم»: its name and time, and the doses, readings
/// and visits that fall nearest to it. The period the patient is in is marked
/// and open, like one that needs attention.
class TodayPrayerPeriod extends StatelessWidget {
  const TodayPrayerPeriod({
    super.key,
    required this.prayer,
    required this.time,
    required this.nextTime,
    required this.prayerTimes,
    required this.occurrences,
    required this.measurementTasks,
    required this.appointments,
    required this.circleId,
    required this.canManage,
    required this.now,
  });
  final Prayer prayer;
  final String time;
  final String? nextTime;
  final Map<Prayer, String> prayerTimes;
  final List<DoseOccurrence> occurrences;
  final List<MeasurementOccurrence> measurementTasks;
  final List<CareAppointment> appointments;
  final String circleId;
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final PeriodEntries entries = PeriodEntries(
      prayer,
      prayerTimes,
      occurrences: occurrences,
      measurementTasks: measurementTasks,
      appointments: appointments,
    );
    final bool current = isInPeriod(now, time, nextTime);
    return PhotoProbe(
      circleId: circleId,
      planIds: [for (final item in entries.doses) item.planId],
      builder: (context, hasPhoto) => PrayerPeriodView(
        prayer: prayer,
        time: time,
        current: current,
        open: periodStartsOpen(entries, now, current: current),
        rows: entries.sorted,
        circleId: circleId,
        canManage: canManage,
        hasPhoto: hasPhoto,
        now: now,
      ),
    );
  }
}
