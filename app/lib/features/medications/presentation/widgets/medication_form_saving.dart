import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
