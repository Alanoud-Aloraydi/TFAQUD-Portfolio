import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
