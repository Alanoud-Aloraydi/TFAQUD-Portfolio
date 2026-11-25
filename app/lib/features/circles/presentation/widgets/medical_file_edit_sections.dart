import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/circles/domain/entities/medical_form.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/allergies_section.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_form.dart';
import 'package:app/features/circles/presentation/widgets/medical_identity_fields.dart';
import 'package:app/features/circles/presentation/widgets/medical_name_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Everything the edit page scrolls through, in order: who the patient is,
/// then the questions about them. A refused save is a toast, but for the
/// birth date, which is shown under its field.
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
  ErrorToast(
    errorKey: isBirthDateError(state.errorKey) ? null : state.errorKey,
    child: const SizedBox(height: AppSpacing.sm),
  ),
];

/// «فصيلة الدم»: one chip per blood type, one of them chosen.
Widget bloodTypeSection(
  BuildContext context, {
  required MedicalForm form,
  required MedicalFileEditCubit cubit,
}) => MedicalSection(
  title: context.tr('circles.blood_type'),
  child: OptionChips(
    options: <ChipOption>[
      for (final String type in MedicalOptions.bloodTypes)
        ChipOption(type, MedicalTexts.bloodTypeLabel(type)),
    ],
    isSelected: (String code) => code == form.bloodType,
    onTap: cubit.chooseBloodType,
  ),
);

/// «الأمراض المزمنة»: the chips, «لا يوجد» and «أخرى» among them, and the
/// text «أخرى» asks for.
Widget conditionsSection(
  BuildContext context, {
  required MedicalFileEditState state,
  required MedicalFileEditCubit cubit,
  required TextEditingController other,
}) => MedicalSection(
  title: context.tr('circles.conditions'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      OptionChips(
        options: <ChipOption>[
          for (final String code in <String>[
            ...MedicalOptions.conditions,
            MedicalOptions.none,
            MedicalOptions.other,
          ])
            ChipOption(code, context.tr('medical.condition.$code')),
        ],
        isSelected: state.form.conditions.contains,
        onTap: cubit.toggleCondition,
      ),
      if (state.form.conditions.contains(MedicalOptions.other)) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        MedicalOtherField(
          controller: other,
          onChanged: cubit.conditionOtherChanged,
          invalid: state.showErrors && state.form.conditionOther.trim().isEmpty,
        ),
      ],
    ],
  ),
);
