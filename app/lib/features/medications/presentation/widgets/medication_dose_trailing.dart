import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_stepper.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_unit_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Beside the dose field: its unit, and the stepper.
class MedicationDoseTrailing extends StatelessWidget {
  const MedicationDoseTrailing({
    super.key,
    required this.data,
    required this.units,
    required this.onChanged,
  });

  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final String unit = context.tr('medications.unit.${data.doseUnit.name}');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // One unit is a word; an injection chooses between mL and units.
        if (units.length > 1)
          InsetChoiceButton(
            label: unit,
            semanticLabel: '${context.tr('medications.dose_unit')}: $unit',
            onPressed: () => _chooseUnit(context),
          )
        else
          Text(unit, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: AppSpacing.sm),
        MedicationDoseStepper(data: data, onChanged: onChanged),
      ],
    );
  }

  Future<void> _chooseUnit(BuildContext context) async {
    final DoseUnit? unit = await chooseDoseUnit(
      context,
      units: units,
      selected: data.doseUnit,
    );
    if (unit == null) return;
    data.doseUnit = unit;
    onChanged();
  }
}
