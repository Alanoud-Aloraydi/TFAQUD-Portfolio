import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The «ظروف القياس» chips, each one toggling in place.
Widget simplifiedMeasureChips(
  BuildContext context,
  SimplifiedMeasureForm form, {
  required MeasurementKind kind,
  required VoidCallback onChanged,
}) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    for (final String code in _codes(form, kind))
      SimplifiedChip(
        context.tr('measurements.condition.$code'),
        selected: form.conditions.contains(code),
        // A meal state replaces the one already chosen (fasting and after
        // a meal cannot both be true): the detailed mode's rule.
        onTap: () {
          form.conditions = MeasurementConditions.toggle(form.conditions, code);
          onChanged();
        },
      ),
  ],
);

/// What the detailed mode offers for [kind], and any the form already has
/// that it no longer offers («قبل النوم»).
List<String> _codes(SimplifiedMeasureForm form, MeasurementKind kind) {
  final List<String> offered = MeasurementConditions.offered(kind);
  return <String>[
    ...offered,
    for (final String code in form.conditions)
      if (!offered.contains(code)) code,
  ];
}
