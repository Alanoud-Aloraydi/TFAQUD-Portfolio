import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/widgets/medication_instruction_chips.dart';
import 'package:app/features/medications/presentation/widgets/medication_instruction_choice.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
