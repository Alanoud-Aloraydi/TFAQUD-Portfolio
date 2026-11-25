import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:app/features/medications/presentation/widgets/next_dose_info.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_window.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_view.dart';
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
