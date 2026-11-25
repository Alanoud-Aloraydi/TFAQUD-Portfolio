import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:app/features/medications/presentation/widgets/next_dose_info.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The dose «اليوم» asks about: its photo, what it is, when it is due and
/// how long is left, and the buttons that answer it once it can be
/// recorded.
class TodayMedicationActionDose extends StatelessWidget {
  const TodayMedicationActionDose({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;

  /// Passed on to the medicine's page.
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final now = PatientClockScope.of(context).now();
    return TodayDoseFrame(
      children: [
        MedicationPhotoBanner(
          circleId: circleId,
          planId: occurrence.planId,
          height: 150,
          bottomGap: AppSpacing.md,
        ),
        TodayDoseTitle(
          status: medicationTimingState(occurrence, now),
          circleId: circleId,
        ),
        const SizedBox(height: AppSpacing.tight),
        NextDoseInfo(
          occurrence: occurrence,
          circleId: circleId,
          canManage: canManage,
        ),
        const SizedBox(height: AppSpacing.lg),
        TodayDoseWindow(occurrence: occurrence, now: now),
        TodayDoseAnswer(occurrence: occurrence, circleId: circleId, now: now),
      ],
    );
  }
}

/// The warm frame «اليوم» draws around the dose it is asking about, so the
/// one task that wants an answer is told apart from the day's list.
class TodayDoseFrame extends StatelessWidget {
  const TodayDoseFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppSemanticColors.accentWarm, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

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
    return MergeSemantics(
      child: Column(
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
          DoseWindowBar(remaining: remaining),
        ],
      ),
    );
  }
}

/// How much of a dose's window is left, as a capsule that empties from the
/// start side. [remaining] is between 0 and 1.
class DoseWindowBar extends StatelessWidget {
  const DoseWindowBar({super.key, required this.remaining});

  final double remaining;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
    );
  }
}
