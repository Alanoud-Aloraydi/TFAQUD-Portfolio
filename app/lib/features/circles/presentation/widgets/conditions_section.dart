import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_other_field.dart';
import 'package:app/features/circles/presentation/widgets/medical_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
