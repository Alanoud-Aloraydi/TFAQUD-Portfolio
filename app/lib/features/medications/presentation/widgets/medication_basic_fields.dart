import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
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

/// Common instructions and the per-version missed-dose threshold. The
/// usual instructions are chips; «أخرى» is a chip too, and only it shows the
/// text field for instructions in the person's own words.
class MedicationInstructionsGroup extends StatelessWidget {
  const MedicationInstructionsGroup({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;

  static const List<String> _presets = <String>[
    'with_meal',
    'before_food',
    'after_food',
    'empty_stomach',
    'before_sleep',
  ];

  /// The chosen chip: a preset whose words are the text, «none» for no
  /// text, else «other».
  String _chosen(BuildContext context) {
    final String text = data.instructions.text.trim();
    if (data.otherInstructions) return _other;
    if (text.isEmpty) return _none;
    for (final String code in _presets) {
      if (text == context.tr('medications.instruction_choice.$code')) {
        return code;
      }
    }
    return _other;
  }

  static const String _none = 'none';
  static const String _other = 'other';

  @override
  Widget build(BuildContext context) {
    final String chosen = _chosen(context);
    return InsetGroup(
      header: context.tr('medications.instructions_section'),
      children: <Widget>[
        InsetBlock(
          semanticLabel: context.tr('medications.instructions'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('medications.instructions')),
              const SizedBox(height: AppSpacing.sm),
              OptionChips(
                options: <ChipOption>[
                  for (final String code in <String>[
                    ..._presets,
                    _other,
                    _none,
                  ])
                    ChipOption(
                      code,
                      context.tr('medications.instruction_choice.$code'),
                    ),
                ],
                isSelected: (String code) => code == chosen,
                onTap: (String code) {
                  if (code == _other) {
                    // The field opens empty, for the person's own words.
                    if (chosen != _other) data.instructions.clear();
                    data.otherInstructions = true;
                  } else {
                    data.otherInstructions = false;
                    data.instructions.text = code == _none
                        ? ''
                        : context.tr('medications.instruction_choice.$code');
                  }
                  onChanged();
                },
              ),
            ],
          ),
        ),
        if (chosen == _other)
          InsetTextRow(
            label: context.tr('medications.instructions_other'),
            hint: context.tr('medications.instructions_other_hint'),
            controller: data.instructions,
            maxLength: 250,
            maxLines: 2,
            autofocus: data.instructions.text.isEmpty,
            onChanged: (_) => onChanged(),
          ),
        MissedAfterField(
          label: context.tr('medications.missed_after'),
          minutes: data.missedAfterMinutes,
          focusNode: data.missedAfterFocus,
          showError: issue?.field == MedicationFormField.missedAfter,
          onChanged: (int? minutes) {
            data.missedAfterMinutes = minutes;
            onChanged();
          },
        ),
      ],
    );
  }
}
