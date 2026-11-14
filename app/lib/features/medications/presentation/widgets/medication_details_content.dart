import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_details.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:app/features/medications/presentation/widgets/medication_pending_revision.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_builder.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_image.dart';
import 'package:app/features/medications/presentation/widgets/medication_revision_history.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class MedicationDetailsContent extends StatelessWidget {
  const MedicationDetailsContent({
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
              MedicationPendingRevision(
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
