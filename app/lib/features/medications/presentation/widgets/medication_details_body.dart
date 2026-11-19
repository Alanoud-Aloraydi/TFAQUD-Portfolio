import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/dose_retention.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/cancel_pending_revision.dart';
import 'package:app/features/medications/presentation/widgets/medication_details.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:app/features/medications/presentation/widgets/medication_pending_revision.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_banner.dart';
import 'package:app/features/medications/presentation/widgets/medication_revision_history.dart';
import 'package:flutter/material.dart';

/// What the medicine's page holds, top to bottom: its photo, the plan, the
/// changes it went through, a change waiting for the patient, and the
/// month of doses with its extra doses.
class MedicationDetailsBody extends StatelessWidget {
  const MedicationDetailsBody({
    super.key,
    required this.circleId,
    required this.plan,
    required this.canManage,
  });

  final String circleId;
  final MedicationPlan plan;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    // The doses before three months are deleted: «أقدم» stops there.
    final DateTime kept = DoseRetention.firstKeptDay(
      PatientClockScope.of(context).today(),
    );
    final DateTime start = plan.version.startsOn;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MedicationPhotoBanner(
          circleId: circleId,
          planId: plan.id,
          height: 268,
          bottomGap: AppSpacing.lg,
        ),
        MedicationDetails(plan: plan),
        const SizedBox(height: AppSpacing.xl),
        MedicationRevisionHistory(plan: plan),
        if (plan.pendingVersion != null) ...[
          const SizedBox(height: AppSpacing.lg),
          MedicationPendingRevision(
            plan: plan,
            circleId: circleId,
            canManage: canManage,
            onCancel: () => cancelPendingRevision(context, circleId, plan),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        MedicationDoseHistory(
          earliest: start.isBefore(kept) ? kept : start,
          circleId: circleId,
          medicine: plan.version,
        ),
      ],
    );
  }
}
