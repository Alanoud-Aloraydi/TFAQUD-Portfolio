import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_controls_layout.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:flutter/material.dart';

/// The buttons that answer the dose of «اليوم», and nothing at all until it
/// can be recorded — an hour before its time at the earliest.
class TodayDoseAnswer extends StatelessWidget {
  const TodayDoseAnswer({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.now,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final bool canRecord = canRecordOccurrence(
      resolved: occurrence.record != null,
      scheduledAt: wallClockAt(occurrence.scheduledOn, occurrence.time),
      now: now,
    );
    if (!canRecord) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DoseRecordControls(
        occurrence: occurrence,
        layout: DoseControlsLayout.today,
        circleId: circleId,
      ),
    );
  }
}
