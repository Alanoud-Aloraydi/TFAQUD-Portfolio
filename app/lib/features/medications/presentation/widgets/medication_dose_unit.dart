import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The dose's unit after its number: one unit is a word; an injection
/// chooses between mL and units.
class MedicationDoseUnit extends StatelessWidget {
  const MedicationDoseUnit({
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
    if (units.length < 2) {
      return Text(unit, style: Theme.of(context).textTheme.bodyLarge);
    }
    return InsetChoiceButton(
      label: unit,
      semanticLabel: '${context.tr('medications.dose_unit')}: $unit',
      onPressed: () => _choose(context),
    );
  }

  Future<void> _choose(BuildContext context) async {
    final DoseUnit? chosen = await chooseDoseUnit(
      context,
      units: units,
      selected: data.doseUnit,
    );
    if (chosen == null) return;
    data.doseUnit = chosen;
    onChanged();
  }
}

/// «وحدة الجرعة»: the unit an injection or a syrup is measured in, when the
/// medicine has more than one.
Future<DoseUnit?> chooseDoseUnit(
  BuildContext context, {
  required List<DoseUnit> units,
  required DoseUnit selected,
}) {
  return showOptionSheet<DoseUnit>(
    context,
    title: context.tr('medications.dose_unit'),
    options: units,
    labelOf: (DoseUnit unit) => context.tr('medications.unit.${unit.name}'),
    selected: selected,
  );
}
