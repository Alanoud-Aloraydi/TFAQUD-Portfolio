import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الآن | تاريخ محدد»: choosing a date opens the date sheet at once, and
/// «الآن» puts the revision on today again.
class MedicationEffectiveChips extends StatelessWidget {
  const MedicationEffectiveChips({
    super.key,
    required this.data,
    required this.onChanged,
    required this.today,
    required this.selected,
    required this.isNow,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final DateTime today;
  final DateTime selected;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    return InsetBlock(
      semanticLabel: context.tr('medications.effective_question'),
      child: OptionChips(
        options: <ChipOption>[
          ChipOption('now', context.tr('medications.now')),
          ChipOption('date', context.tr('medications.specific_date')),
        ],
        isSelected: (String code) => code == 'now' ? isNow : !isNow,
        onTap: (String code) {
          if (code == 'now') {
            data.effectiveFromOn = today;
            onChanged();
          } else {
            _chooseDate(context);
          }
        },
      ),
    );
  }

  Future<void> _chooseDate(BuildContext context) async {
    final date = await showTafaqodDateSheet(
      context,
      title: context.tr('medications.effective_from'),
      initialDate: selected,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (date == null) return;
    data.effectiveFromOn = date;
    onChanged();
  }
}
