import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        InsetTextRow(
          label: context.tr('medications.strength'),
          hint: context.tr('medications.strength_hint'),
          controller: data.strength,
          focusNode: data.strengthFocus,
          errorText: issue?.field == MedicationFormField.strength
              ? context.tr('medications.positive_number')
              : null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            const WesternDigitsFormatter(decimal: true),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (_) => onChanged(),
          trailing: InsetChoiceButton(
            label: context.tr(
              'medications.strength_display.${data.strengthUnit.name}',
            ),
            semanticLabel:
                '${context.tr('medications.strength_unit')}: '
                '${context.tr('medications.strength_display.${data.strengthUnit.name}')}',
            onPressed: () => _chooseStrengthUnit(context),
          ),
        ),
        InsetBlock(
          semanticLabel: context.tr('medications.dosage_form'),
          child: OptionChips(
            options: <ChipOption>[
              for (final DosageForm form in DosageForm.values)
                ChipOption(
                  form.name,
                  context.tr('medications.form.${form.name}'),
                ),
            ],
            isSelected: (String code) => code == data.form.name,
            onTap: (String code) {
              final form = DosageForm.values.byName(code);
              if (form == data.form) return;
              data.form = form;
              for (final schedule in data.schedules) {
                if (!form.doseUnits.contains(schedule.doseUnit)) {
                  schedule.doseUnit = form.defaultDoseUnit;
                }
              }
              onChanged();
            },
          ),
        ),
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

  Future<void> _chooseStrengthUnit(BuildContext context) async {
    final StrengthUnit? unit = await showOptionSheet<StrengthUnit>(
      context,
      title: context.tr('medications.strength_unit'),
      options: StrengthUnit.values,
      labelOf: (StrengthUnit unit) =>
          context.tr('medications.strength_display.${unit.name}'),
      selected: data.strengthUnit,
    );
    if (unit == null) return;
    data.strengthUnit = unit;
    onChanged();
  }
}
