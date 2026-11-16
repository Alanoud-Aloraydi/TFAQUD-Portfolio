import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the medicine comes as: tablets, a liquid, an inhaler. Changing it
/// moves every dose time to a unit the new form is measured in.
class MedicationDosageFormChips extends StatelessWidget {
  const MedicationDosageFormChips({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InsetBlock(
      semanticLabel: context.tr('medications.dosage_form'),
      child: OptionChips(
        options: <ChipOption>[
          for (final DosageForm form in DosageForm.values)
            ChipOption(form.name, context.tr('medications.form.${form.name}')),
        ],
        isSelected: (String code) => code == data.form.name,
        onTap: (String code) => _choose(DosageForm.values.byName(code)),
      ),
    );
  }

  void _choose(DosageForm form) {
    if (form == data.form) return;
    data.form = form;
    for (final schedule in data.schedules) {
      if (!form.doseUnits.contains(schedule.doseUnit)) {
        schedule.doseUnit = form.defaultDoseUnit;
      }
    }
    onChanged();
  }
}
