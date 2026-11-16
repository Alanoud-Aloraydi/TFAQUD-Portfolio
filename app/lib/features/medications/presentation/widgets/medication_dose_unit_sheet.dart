import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
