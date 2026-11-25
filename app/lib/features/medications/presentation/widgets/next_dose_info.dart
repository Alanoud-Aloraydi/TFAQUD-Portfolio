import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/next_dose_lines.dart';
import 'package:flutter/material.dart';

/// The next dose of «اليوم»: its time, large, beside the medicine and how
/// much to take.
class NextDoseInfo extends StatelessWidget {
  const NextDoseInfo({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NextDoseClock(time: occurrence.time),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: NextDoseLines(
            occurrence: occurrence,
            circleId: circleId,
            canManage: canManage,
          ),
        ),
      ],
    );
  }
}

/// A dose's time, large: the hour and minutes on one line and «ص» or «م»
/// under them, so the number itself reads from across the room.
class NextDoseClock extends StatelessWidget {
  const NextDoseClock({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> parts = clockText(time).split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(parts.first, style: text.displaySmall),
        if (parts.length > 1) Text(parts.last, style: text.labelMedium),
      ],
    );
  }
}

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
