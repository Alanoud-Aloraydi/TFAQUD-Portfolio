import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_form.dart';
import 'package:app/features/circles/presentation/widgets/medical_identity_fields.dart';
import 'package:app/features/circles/presentation/widgets/medical_name_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الحساسية»: one card holds the whole question. «لا توجد حساسية» answers
/// it and stays a chip, the way «لا يوجد» does under «الأمراض المزمنة»; the
/// card is what says the two kinds belong to it, so nothing has to be drawn
/// between them.
Widget allergiesSection(
  BuildContext context, {
  required MedicalFileEditState state,
  required MedicalFileEditCubit cubit,
  required MedicalFormFields fields,
}) => MedicalSection(
  title: context.tr('circles.allergies_title'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      OptionChips(
        options: <ChipOption>[
          ChipOption(MedicalOptions.none, context.tr('circles.no_allergies')),
        ],
        isSelected: (String code) => state.form.noAllergies,
        onTap: (String code) => cubit.toggleNoAllergies(),
      ),
      if (!state.form.noAllergies) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        ...allergyKindChips(
          context,
          labelKey: 'circles.allergy_group_medicine',
          group: 'medication',
          codes: MedicalOptions.medications,
          otherLabel: context.tr('circles.allergy_other_medicine'),
          isSelected: state.form.medication.contains,
          onTap: cubit.toggleMedication,
          other: fields.medicationOther,
          onOtherChanged: cubit.medicationOtherChanged,
          otherInvalid:
              state.showErrors && state.form.medicationOther.trim().isEmpty,
        ),
        const SizedBox(height: AppSpacing.md),
        ...allergyKindChips(
          context,
          labelKey: 'circles.allergy_group_food',
          group: 'food',
          codes: MedicalOptions.foods,
          otherLabel: context.tr('circles.allergy_other_food'),
          isSelected: state.form.food.contains,
          onTap: cubit.toggleFood,
          other: fields.foodOther,
          onOtherChanged: cubit.foodOtherChanged,
          otherInvalid: state.showErrors && state.form.foodOther.trim().isEmpty,
        ),
      ],
    ],
  ),
);

/// One kind of allergy inside the «الحساسية» card: its label, smaller and
/// lighter than the heading above so it reads as a part of the question and
/// not a section of its own, then the chips and the text «أخرى» asks for.
///
/// [otherLabel] names that chip, because a screen reader reads a chip on its
/// own and «دواء آخر» and «طعام آخر» must stay told apart.
List<Widget> allergyKindChips(
  BuildContext context, {
  required String labelKey,
  required String group,
  required List<String> codes,
  required String otherLabel,
  required bool Function(String) isSelected,
  required ValueChanged<String> onTap,
  required TextEditingController other,
  required ValueChanged<String> onOtherChanged,
  required bool otherInvalid,
}) => <Widget>[
  Text(
    context.tr(labelKey),
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.tokens.textSecondary),
  ),
  const SizedBox(height: AppSpacing.xs),
  OptionChips(
    options: <ChipOption>[
      for (final String code in <String>[...codes, MedicalOptions.other])
        ChipOption(
          code,
          code == MedicalOptions.other
              ? otherLabel
              : context.tr('medical.$group.$code'),
        ),
    ],
    isSelected: isSelected,
    onTap: onTap,
  ),
  if (isSelected(MedicalOptions.other)) ...<Widget>[
    const SizedBox(height: AppSpacing.md),
    MedicalOtherField(
      controller: other,
      onChanged: onOtherChanged,
      invalid: otherInvalid,
    ),
  ],
];
