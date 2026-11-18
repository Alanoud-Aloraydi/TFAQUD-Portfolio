import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_issue_focus.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_saving.dart';
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
