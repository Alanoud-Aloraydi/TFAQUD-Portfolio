import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «مستمر | حتى تاريخ»: choosing a date opens the date sheet at once, and
/// «مستمر» clears the end again.
class MedicationDurationChips extends StatelessWidget {
  const MedicationDurationChips({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InsetBlock(
      semanticLabel: context.tr('medications.duration'),
      child: OptionChips(
        options: <ChipOption>[
          ChipOption('continuous', context.tr('medications.continuous')),
          ChipOption('dated', context.tr('medications.until_date')),
        ],
        isSelected: (String code) =>
            code == 'continuous' ? data.endsOn == null : data.endsOn != null,
        onTap: (String code) => _choose(context, code),
      ),
    );
  }

  Future<void> _choose(BuildContext context, String code) async {
    if (code == 'continuous') {
      data.endsOn = null;
      onChanged();
      return;
    }
    final first = data.effectiveFromOn ?? data.startsOn;
    final selected = await showTafaqodDateSheet(
      context,
      title: context.tr('medications.ends'),
      initialDate: data.endsOn ?? first,
      firstDate: first,
      lastDate: first.add(const Duration(days: 3650)),
    );
    if (selected == null) return;
    data.endsOn = selected;
    onChanged();
  }
}
