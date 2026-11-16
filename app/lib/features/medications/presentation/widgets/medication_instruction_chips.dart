import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_instruction_choice.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
