import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows the planned time and the medicine's own missed-dose boundary of
/// an unrecorded dose; [now] is the patient's wall time
/// ([PatientClock.now]).
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
    final scheduled = wallClockAt(occurrence.scheduledOn, occurrence.time);
    final missed = scheduled.add(
      Duration(minutes: occurrence.missedAfterMinutes),
    );
    final remainingSeconds = missed.difference(now).inSeconds;
    final windowSeconds = occurrence.missedAfterMinutes * 120;
    final remaining = (remainingSeconds / windowSeconds).clamp(0.0, 1.0);
    final minutesUntilDue = (scheduled.difference(now).inSeconds + 59) ~/ 60;
    final status = medicationTimingState(occurrence, now);
    final label = minutesUntilDue > 0
        ? afterDuration(context, minutesUntilDue)
        : context.tr('today_dashboard.status.${status!.name}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(TafaqodPhosphorIcons.clock, size: 18),
            const SizedBox(width: AppSpacing.tight),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(
              context.tr(
                'today_dashboard.missed_at',
                args: [wallTimeText(missed)],
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.capsule),
          child: SizedBox(
            height: AppSpacing.tight,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: AppSemanticColors.doseTrack),
                ),
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: remaining,
                    child: const ColoredBox(
                      color: AppSemanticColors.textSupporting,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
