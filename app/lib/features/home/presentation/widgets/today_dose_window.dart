import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows the planned time and the medicine's own missed-dose boundary.
class TodayDoseWindow extends StatelessWidget {
  const TodayDoseWindow({
    super.key,
    required this.occurrence,
    required this.now,
  });

  final DoseOccurrence occurrence;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final parts = occurrence.time.split(':');
    final scheduled = DateTime.utc(
      occurrence.scheduledOn.year,
      occurrence.scheduledOn.month,
      occurrence.scheduledOn.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final grace = occurrence.missedAfterMinutes;
    final start = scheduled.subtract(Duration(minutes: grace * 4 ~/ 5));
    final missed = scheduled.add(Duration(minutes: grace));
    final total = missed.difference(start).inSeconds;
    final dueFraction = scheduled.difference(start).inSeconds / total;
    final nowFraction = (now.difference(start).inSeconds / total).clamp(
      0.0,
      1.0,
    );
    final nowTime =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final missedTime =
        '${missed.hour.toString().padLeft(2, '0')}:'
        '${missed.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfacePlan,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: AppSpacing.lg,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: AppSpacing.tight,
                    bottom: AppSpacing.tight,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (dueFraction * 100).round(),
                          child: const ColoredBox(
                            color: AppSemanticColors.doseTrack,
                          ),
                        ),
                        Expanded(
                          flex: ((1 - dueFraction) * 100).round(),
                          child: const ColoredBox(
                            color: AppSemanticColors.borderAttention,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    start: constraints.maxWidth * nowFraction,
                    top: 0,
                    bottom: 0,
                    child: const ColoredBox(
                      color: AppSemanticColors.textPrimary,
                      child: SizedBox(width: AppSpacing.xs),
                    ),
                  ),
                  PositionedDirectional(
                    start: constraints.maxWidth * dueFraction,
                    top: 0,
                    bottom: 0,
                    child: const ColoredBox(
                      color: AppSemanticColors.doseDueMarker,
                      child: SizedBox(width: AppSpacing.xs),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimeLabel(
                label: context.tr('today_dashboard.now'),
                time: formatMedicationTime(context, nowTime),
              ),
              _TimeLabel(
                label: context.tr('today_dashboard.due'),
                time: formatMedicationTime(context, occurrence.time),
              ),
              _TimeLabel(
                label: context.tr('today_dashboard.missed_after'),
                time: formatMedicationTime(context, missedTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text(time, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
