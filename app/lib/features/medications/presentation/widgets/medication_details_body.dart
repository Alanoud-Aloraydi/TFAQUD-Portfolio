import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_details.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// Displays the medication revision history UI.
class MedicationRevisionHistory extends StatelessWidget {
  const MedicationRevisionHistory({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final history = plan.history.isEmpty ? [plan.version] : plan.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('medications.revision_history'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = history.length - 1; index >= 0; index--) ...[
          MedicationRevisionEntry(
            version: history[index],
            previous: index == 0 ? null : history[index - 1],
          ),
          if (index > 0) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// One version of a medicine in «سجل التعديلات»: the day it took over and
/// what the medicine was then, the schedule it replaced crossed out.
class MedicationRevisionEntry extends StatelessWidget {
  const MedicationRevisionEntry({
    super.key,
    required this.version,
    required this.previous,
  });

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) => MedicationVersionCard(
    title: context.tr(
      previous == null
          ? 'medications.initial_version'
          : 'medications.revised_on',
      args: <String>[formatMedicationDate(context, version.effectiveFromOn)],
    ),
    version: version,
    previous: previous,
  );
}

/// Asks before dropping a change that waits for the patient, then drops it
/// and closes the medicine's page. A refused change leaves the page open
/// with the cubit's own words.
Future<void> cancelPendingRevision(
  BuildContext context,
  String circleId,
  MedicationPlan plan,
) async {
  final confirmed = await showAppAlert<bool>(
    context,
    title: context.tr('medications.cancel_pending_title'),
    message: CareVoice.tr(
      context,
      circleId,
      'medications.cancel_pending_message',
    ),
    actions: [
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('medications.cancel_pending'),
        value: true,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  final cubit = context.read<MedicationsCubit>();
  final changed = await cubit.cancelPending(plan);
  if (!context.mounted) return;
  if (changed) {
    AppToast.show(context, 'toast.change_canceled');
    context.pop(true);
    return;
  }
  final message = cubit.state.messageKey;
  if (message != null) {
    AppToast.show(context, message, kind: ToastKind.error);
  }
}

/// The change that waits for its first day, on the medicine's own page, in
/// the same card as each step of «سجل التعديلات»: the day it takes over,
/// what that means for the past doses, the medicine as it will be (the
/// schedule of now crossed out), and «إلغاء التعديل» for a member who may
/// drop it.
class MedicationPendingRevision extends StatelessWidget {
  const MedicationPendingRevision({
    super.key,
    required this.plan,
    required this.circleId,
    required this.canManage,
    required this.onCancel,
  });

  final MedicationPlan plan;
  final String circleId;
  final bool canManage;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final MedicationVersion pending = plan.pendingVersion!;
    return MedicationVersionCard(
      title: context.tr(
        'medications.pending_revision',
        args: <String>[formatMedicationDate(context, pending.effectiveFromOn)],
      ),
      note: CareVoice.tr(context, circleId, 'medications.effective_hint'),
      version: pending,
      previous: plan.version,
      action: canManage
          ? TextButton(
              onPressed: onCancel,
              child: Text(context.tr('medications.cancel_pending')),
            )
          : null,
    );
  }
}
