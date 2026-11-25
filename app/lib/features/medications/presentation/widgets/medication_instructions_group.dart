import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final String chosen = instructionChoice(context, data);
    return InsetGroup(
      header: context.tr('medications.instructions_section'),
      children: <Widget>[
        MedicationInstructionChips(
          data: data,
          chosen: chosen,
          onChanged: onChanged,
        ),
        if (chosen == otherInstruction)
          InsetTextRow(
            label: context.tr('medications.instructions_other'),
            hint: context.tr('medications.instructions_other_hint'),
            controller: data.instructions,
            maxLength: 250,
            maxLines: 2,
            autofocus: data.instructions.text.isEmpty,
            onChanged: (_) => onChanged(),
          ),
        // Without a dose time no dose can be missed.
        if (data.schedules.isNotEmpty)
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

/// The usual instructions as chips, with «أخرى» and «بدون» at the end.
class MedicationInstructionChips extends StatelessWidget {
  const MedicationInstructionChips({
    super.key,
    required this.data,
    required this.chosen,
    required this.onChanged,
  });

  final MedicationFormData data;
  final String chosen;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InsetBlock(
      semanticLabel: context.tr('medications.instructions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('medications.instructions')),
          const SizedBox(height: AppSpacing.sm),
          OptionChips(
            options: <ChipOption>[
              for (final String code in <String>[
                ...instructionPresets,
                otherInstruction,
                noInstruction,
              ])
                ChipOption(
                  code,
                  context.tr('medications.instruction_choice.$code'),
                ),
            ],
            isSelected: (String code) => code == chosen,
            onTap: (String code) => _choose(context, code),
          ),
        ],
      ),
    );
  }

  void _choose(BuildContext context, String code) {
    if (code == otherInstruction) {
      // The field opens empty, for the person's own words.
      if (chosen != otherInstruction) data.instructions.clear();
      data.otherInstructions = true;
    } else {
      data.otherInstructions = false;
      data.instructions.text = code == noInstruction
          ? ''
          : context.tr('medications.instruction_choice.$code');
    }
    onChanged();
  }
}

/// The instructions almost every medicine is taken with.
const List<String> instructionPresets = <String>[
  'with_meal',
  'before_food',
  'after_food',
  'empty_stomach',
  'before_sleep',
];

/// No instructions at all.
const String noInstruction = 'none';

/// Instructions in the person's own words.
const String otherInstruction = 'other';

/// The chosen chip: a preset whose words are the text, «none» for no text,
/// else «other».
String instructionChoice(BuildContext context, MedicationFormData data) {
  final String text = data.instructions.text.trim();
  if (data.otherInstructions) return otherInstruction;
  if (text.isEmpty) return noInstruction;
  for (final String code in instructionPresets) {
    if (text == context.tr('medications.instruction_choice.$code')) {
      return code;
    }
  }
  return otherInstruction;
}
