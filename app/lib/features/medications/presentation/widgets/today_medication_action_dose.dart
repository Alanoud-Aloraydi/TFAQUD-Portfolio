import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_banner.dart';
import 'package:app/features/medications/presentation/widgets/next_dose_info.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_answer.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_frame.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_title.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_window.dart';
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
