import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_body.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The form as a page: its own bar over what it asks for, and a guard on
/// the way back while anything is unsaved.
class MedicationFormPage extends StatelessWidget {
  const MedicationFormPage({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    final saving = context.select(
      (MedicationsCubit cubit) =>
          cubit.state.status == MedicationsStatus.saving,
    );
    return PopScope(
      canPop: !state.dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) state.confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          titleSpacing: AppSpacing.lg,
          title: MedicationFormBar(
            isEdit: state.widget.plan != null,
            saving: saving,
            onCancel: state.cancel,
            onSave: state.submit,
          ),
        ),
        body: MedicationFormBody(state: state),
      ),
    );
  }
}

/// Leaving the form: nothing typed closes it, anything typed asks first.
extension MedicationFormDiscard on MedicationFormState {
  void cancel() {
    if (dirty) {
      confirmDiscard();
    } else {
      context.pop();
    }
  }

  Future<void> confirmDiscard() async {
    final discard = await showAppAlert<bool>(
      context,
      title: context.tr('medications.discard_title'),
      message: context.tr('medications.discard_message'),
      actions: [
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('medications.discard_confirm'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (discard == true && mounted) {
      dirty = false;
      context.pop();
    }
  }
}

/// The form that adds a medicine or changes one. [plan] is the medicine
/// being changed; null adds a new one.
class MedicationForm extends StatefulWidget {
  const MedicationForm({super.key, required this.circleId, this.plan});

  final String circleId;
  final MedicationPlan? plan;

  @override
  State<MedicationForm> createState() => MedicationFormState();
}

/// The form's own bar: «إلغاء», the title, and the green save button, on one
/// glass capsule.
class MedicationFormBar extends StatelessWidget {
  const MedicationFormBar({
    super.key,
    required this.isEdit,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isEdit;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.capsule),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(context.tr('common.cancel')),
            ),
            Expanded(
              child: Text(
                context.tr(
                  isEdit ? 'medications.edit_title' : 'medications.add_title',
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppSemanticColors.actionPrimary,
                  foregroundColor: AppSemanticColors.onActionPrimary,
                  minimumSize: const Size(58, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                onPressed: saving ? null : onSave,
                child: Text(context.tr('medications.save_changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saving the form: what it refuses before sending, then the plan itself.
/// The photo follows in [MedicationPhotoSaving], since its path needs the
/// plan's id; a plan already saved is not sent twice.
extension MedicationFormSaving on MedicationFormState {
  Future<void> submit() async {
    final String? saved = savedPlanId;
    if (saved != null) return savePhoto(saved);
    // A refusal said again is shown again.
    if (errorKey != null) update(() => errorKey = null);
    if (widget.plan == null &&
        data.startsOn.isBefore(PatientClockScope.of(context).today())) {
      update(() => errorKey = 'medications.start_in_past');
      return;
    }
    final MedicationFormIssue? found =
        widget.plan != null && !medicalFieldsDirty ? null : data.firstIssue();
    if (found != null) {
      update(() => issue = found);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) await focusMedicationIssue(data, found);
      return;
    }
    final cubit = context.read<MedicationsCubit>();
    var done = widget.plan != null && !medicalFieldsDirty;
    if (!done) {
      final draft = data.toDraft();
      if (draft == null) return;
      done = widget.plan == null
          ? await cubit.create(draft)
          : await cubit.revise(widget.plan!, draft);
    }
    if (!mounted) return;
    if (!done) {
      update(() => errorKey = cubit.state.messageKey ?? 'error.unknown');
      return;
    }
    final id =
        widget.plan?.id ??
        (cubit.state.plans.isEmpty ? null : cubit.state.plans.last.id);
    if (id == null) return;
    savedPlanId = id;
    await savePhoto(id);
  }
}

/// Opens the keyboard on the field the form refused and scrolls it into
/// view, so the person sees what is being asked of them.
Future<void> focusMedicationIssue(
  MedicationFormData data,
  MedicationFormIssue issue,
) async {
  final FocusNode node = switch (issue.field) {
    MedicationFormField.name => data.nameFocus,
    MedicationFormField.strength => data.strengthFocus,
    MedicationFormField.period => data.periodFocus,
    MedicationFormField.missedAfter => data.missedAfterFocus,
    MedicationFormField.dose => data.schedules[issue.scheduleIndex!].doseFocus,
    MedicationFormField.weekdays =>
      data.schedules[issue.scheduleIndex!].weekdaysFocus,
  };
  node.requestFocus();
  final BuildContext? fieldContext = node.context;
  if (fieldContext != null) {
    await Scrollable.ensureVisible(
      fieldContext,
      duration: AppMotion.formScroll,
    );
  }
}
