import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/allergies_section.dart';
import 'package:app/features/circles/presentation/widgets/blood_type_section.dart';
import 'package:app/features/circles/presentation/widgets/conditions_section.dart';
import 'package:app/features/circles/presentation/widgets/medical_form_fields.dart';
import 'package:app/features/circles/presentation/widgets/medical_identity_fields.dart';
import 'package:app/features/circles/presentation/widgets/medical_name_fields.dart';
import 'package:flutter/material.dart';

/// Everything the edit page scrolls through, in order: who the patient is,
/// then the questions about them, then whatever went wrong on the last save.
List<Widget> medicalFileEditSections(
  BuildContext context, {
  required MedicalFileEditState state,
  required MedicalFileEditCubit cubit,
  required MedicalFormFields fields,
}) => <Widget>[
  MedicalNameFields(state: state, cubit: cubit, fields: fields),
  const SizedBox(height: AppSpacing.lg),
  ...medicalIdentityFields(context, state: state, cubit: cubit),
  bloodTypeSection(context, form: state.form, cubit: cubit),
  conditionsSection(
    context,
    state: state,
    cubit: cubit,
    other: fields.conditionOther,
  ),
  allergiesSection(context, state: state, cubit: cubit, fields: fields),
  if (state.errorKey != null) ...<Widget>[
    const SizedBox(height: AppSpacing.lg),
    InlineError(messageKey: state.errorKey!),
  ],
  const SizedBox(height: AppSpacing.sm),
];
