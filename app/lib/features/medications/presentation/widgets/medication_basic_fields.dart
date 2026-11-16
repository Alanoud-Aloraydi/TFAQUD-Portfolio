import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/widgets/medication_dosage_form_chips.dart';
import 'package:app/features/medications/presentation/widgets/medication_strength_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The medicine's name, strength, form, and reason in one grouped section.
class MedicationBasicFields extends StatelessWidget {
  const MedicationBasicFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.photoField,
    this.issue,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final Widget? photoField;
  final MedicationFormIssue? issue;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('medications.basic_details'),
      children: <Widget>[
        if (photoField != null)
          InsetBlock(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: photoField,
            ),
          ),
        InsetTextRow(
          label: context.tr('medications.name'),
          hint: context.tr('medications.name_hint'),
          controller: data.name,
          focusNode: data.nameFocus,
          errorText: issue?.field == MedicationFormField.name
              ? context.tr('common.field_required')
              : null,
          maxLength: 50,
          onChanged: (_) => onChanged(),
        ),
        MedicationStrengthRow(data: data, issue: issue, onChanged: onChanged),
        MedicationDosageFormChips(data: data, onChanged: onChanged),
        InsetTextRow(
          label: context.tr('medications.reason'),
          hint: context.tr('medications.optional'),
          controller: data.reason,
          maxLength: 100,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
