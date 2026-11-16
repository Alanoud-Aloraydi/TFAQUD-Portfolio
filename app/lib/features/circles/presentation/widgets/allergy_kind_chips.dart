import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/widgets/medical_other_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
