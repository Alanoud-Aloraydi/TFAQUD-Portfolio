import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_details.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// One medicine's page: its details, versions, pending change and dose
/// history. Opened from the plan, record and «اليوم» rows with `extra`
/// [canManage]; the route builds its [MedicationsCubit] (`loadPlan`).
class MedicationDetailsPage extends StatelessWidget {
  const MedicationDetailsPage({
    super.key,
    required this.circleId,
    required this.planId,
    required this.canManage,
  });

  final String circleId;
  final String planId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) {
        if (state.status == MedicationsStatus.loading) {
          // The page keeps its bar while it loads, so only the content
          // changes when it comes.
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('medications.details'))),
            body: const MedicationDetailsSkeleton(),
          );
        }
        if (state.status == MedicationsStatus.failure || state.plans.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: RetryView(
              messageKey: state.messageKey ?? 'error.resource_not_found',
              onRetry: () =>
                  context.read<MedicationsCubit>().loadPlan(circleId, planId),
            ),
          );
        }
        return _Content(
          key: ValueKey(state.plans.first.version.number),
          circleId: circleId,
          plan: state.plans.first,
          canManage: canManage,
        );
      },
    );
  }
}

/// Renders the content element of medication details page.
class _Content extends StatelessWidget {
  const _Content({
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
    final today = PatientClockScope.of(context).today();
    // Calendar days, so a phone's own DST change never moves the range.
    final from = DateTime(today.year, today.month, today.day - 31);
    final start = plan.version.startsOn.isAfter(from)
        ? plan.version.startsOn
        : from;
    return BlocProvider(
      create: (_) => MedicationOccurrencesCubit(
        GetIt.I<MedicationsUseCase>(),
        photoChanges: GetIt.I<PrivatePhotoRepository>().changes,
      )..load(circleId, start, today, planId: plan.id),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medications.details')),
          actions: [
            if (canManage && !plan.isPreviousOn(today))
              IconButton(
                tooltip: context.tr('medications.edit_title'),
                onPressed: () => _edit(context),
                icon: const Icon(AppIcons.pencil),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            MedicationPhotoBuilder(
              circleId: circleId,
              planId: plan.id,
              builder: (context, bytes) => bytes == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: MedicationPhotoImage(bytes: bytes, height: 268),
                    ),
            ),
            MedicationDetails(plan: plan),
            const SizedBox(height: AppSpacing.xl),
            MedicationRevisionHistory(plan: plan),
            if (plan.pendingVersion != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _PendingRevision(
                plan: plan,
                circleId: circleId,
                canManage: canManage,
                onCancel: () => _cancelPending(context),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            MedicationDoseHistory(
              earliest: plan.version.startsOn,
              circleId: circleId,
            ),
            if (canManage && !plan.isPreviousOn(today)) ...[
              const SizedBox(height: AppSpacing.xl),
              // Ending the treatment cannot be undone: the error red.
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppSemanticColors.statusError,
                ),
                onPressed: () => _discontinue(context),
                child: Text(context.tr('medications.discontinue')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final changed = await context.push<bool>(
      Routes.editMedication(circleId, plan.id),
    );
    if (changed == true && context.mounted) {
      context.pop(true);
    }
  }

  Future<void> _discontinue(BuildContext context) async {
    final confirmed = await showAppAlert<bool>(
      context,
      title: context.tr('medications.discontinue_title'),
      message: context.tr('medications.discontinue_message'),
      actions: [
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('medications.discontinue_confirm'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final changed = await context.read<MedicationsCubit>().discontinue(plan);
    if (!context.mounted) return;
    if (changed) {
      AppToast.show(context, 'toast.medication_stopped');
      context.pop(true);
      return;
    }
    _showFailure(context);
  }

  Future<void> _cancelPending(BuildContext context) async {
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
    final changed = await context.read<MedicationsCubit>().cancelPending(plan);
    if (!context.mounted) return;
    if (changed) {
      AppToast.show(context, 'toast.change_canceled');
      context.pop(true);
      return;
    }
    _showFailure(context);
  }

  /// The cubit's message after a refused change, as a snack bar.
  void _showFailure(BuildContext context) {
    final message = context.read<MedicationsCubit>().state.messageKey;
    if (message != null) {
      AppToast.show(context, message, kind: ToastKind.error);
    }
  }
}

/// Renders the pending revision element of medication details page.
class _PendingRevision extends StatelessWidget {
  const _PendingRevision({
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
    final pending = plan.pendingVersion!;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppSemanticColors.textSupporting, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'medications.pending_revision',
                args: [formatMedicationDate(context, pending.effectiveFromOn)],
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(CareVoice.tr(context, circleId, 'medications.effective_hint')),
            const SizedBox(height: AppSpacing.md),
            Text(pending.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              context.tr(
                'medications.pending_strength',
                args: [
                  formatMedicationNumber(pending.strengthValue),
                  context.tr(
                    'medications.strength_display.${pending.strengthUnit.name}',
                  ),
                  context.tr('medications.form.${pending.dosageForm.name}'),
                ],
              ),
            ),
            if (pending.instructions case final instructions?)
              Text(instructions),
            Text(
              arabicCount(
                context,
                ArabicCount.minutes,
                pending.missedAfterMinutes,
              ),
            ),
            for (final schedule in pending.schedules)
              Text(
                context.tr(
                  'medications.pending_schedule',
                  args: [
                    clockText(schedule.time),
                    formatMedicationNumber(schedule.doseValue),
                    context.tr('medications.unit.${schedule.doseUnit.name}'),
                  ],
                ),
              ),
            if (canManage)
              TextButton(
                onPressed: onCancel,
                child: Text(context.tr('medications.cancel_pending')),
              ),
          ],
        ),
      ),
    );
  }
}
