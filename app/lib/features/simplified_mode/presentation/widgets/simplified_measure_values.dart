import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_field.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_value_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The number being typed: one big card for glucose, or the upper and the
/// lower card one under the other, where a tap chooses which one the
/// keypad fills.
Widget simplifiedMeasureValues(
  BuildContext context,
  SimplifiedMeasureForm form, {
  required bool glucose,
  required ValueChanged<SimplifiedMeasureField> onPick,
}) {
  if (glucose) {
    return SimplifiedMeasureValueCard(
      value: form.values[SimplifiedMeasureField.glucose]!,
      unit: context.tr('measurements.glucose_unit'),
      active: true,
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final (SimplifiedMeasureField field, String label)
          in <(SimplifiedMeasureField, String)>[
            (SimplifiedMeasureField.upper, context.tr('simplified_mode.upper')),
            (SimplifiedMeasureField.lower, context.tr('simplified_mode.lower')),
          ]) ...<Widget>[
        if (field == SimplifiedMeasureField.lower) const SizedBox(height: 8),
        Semantics(
          button: true,
          selected: form.upperOrLower == field,
          label: spoken(label),
          child: GestureDetector(
            onTap: () => onPick(field),
            child: SimplifiedMeasureValueCard(
              value: form.values[field]!,
              unit: label,
              active: form.upperOrLower == field,
              small: true,
            ),
          ),
        ),
      ],
    ],
  );
}
