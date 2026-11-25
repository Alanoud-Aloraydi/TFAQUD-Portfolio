import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/features/circles/domain/entities/medical_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/read_only_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's two name fields while they may still be edited, else the
/// saved name with the note that says why it cannot be.
class MedicalNameFields extends StatelessWidget {
  const MedicalNameFields({
    super.key,
    required this.state,
    required this.cubit,
    required this.fields,
  });

  final MedicalFileEditState state;
  final MedicalFileEditCubit cubit;
  final MedicalFormFields fields;

  @override
  Widget build(BuildContext context) {
    if (!state.namesEditable) {
      return ReadOnlyField(
        label: context.tr('circles.name'),
        note: context.tr('circles.file_name_note'),
        child: Text(
          state.file!.patient.fullName,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    final String requiredText = context.tr('common.field_required');
    final bool show = state.showErrors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LabeledTextField(
          label: context.tr('circles.patient_first_name'),
          controller: fields.firstName,
          maxLength: NameLimits.name,
          onChanged: cubit.firstNameChanged,
          errorText: show && state.firstName.trim().isEmpty
              ? requiredText
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('circles.patient_last_name'),
          controller: fields.lastName,
          maxLength: NameLimits.name,
          onChanged: cubit.lastNameChanged,
          textInputAction: TextInputAction.done,
          errorText: show && state.lastName.trim().isEmpty
              ? requiredText
              : null,
        ),
      ],
    );
  }
}

/// The typed text of the edit form: created from the saved values, and
/// cleared again whenever the state clears it, which happens when «أخرى» is
/// turned off or «لا توجد حساسية» is chosen.
class MedicalFormFields {
  MedicalFormFields(MedicalFileEditState state)
    : firstName = TextEditingController(text: state.firstName),
      lastName = TextEditingController(text: state.lastName),
      conditionOther = TextEditingController(text: state.form.conditionOther),
      medicationOther = TextEditingController(text: state.form.medicationOther),
      foodOther = TextEditingController(text: state.form.foodOther);

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController conditionOther;
  final TextEditingController medicationOther;
  final TextEditingController foodOther;

  void syncWith(MedicalForm form) {
    if (form.conditionOther.isEmpty) conditionOther.clear();
    if (form.medicationOther.isEmpty) medicationOther.clear();
    if (form.foodOther.isEmpty) foodOther.clear();
  }

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    conditionOther.dispose();
    medicationOther.dispose();
    foodOther.dispose();
  }
}
