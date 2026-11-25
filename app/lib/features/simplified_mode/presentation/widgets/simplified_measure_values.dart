import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_scaffold.dart';
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

/// The reading [form] holds, or null while one of its numbers is missing.
/// The note travels only with «أخرى».
SimplifiedReading? simplifiedMeasureReading(SimplifiedMeasureForm form) {
  final MeasurementKind? kind = form.kind;
  if (kind == null) return null;
  final bool glucose = kind == MeasurementKind.glucose;
  final int? one = int.tryParse(
    form.values[glucose
        ? SimplifiedMeasureField.glucose
        : SimplifiedMeasureField.upper]!,
  );
  final int? two = glucose
      ? null
      : int.tryParse(form.values[SimplifiedMeasureField.lower]!);
  if (one == null || (!glucose && two == null)) return null;
  final String note = form.note.text.trim();
  return SimplifiedReading(
    kind: kind,
    valueOne: one,
    valueTwo: two,
    conditions: form.conditions,
    note: form.conditions.contains('other') && note.isNotEmpty ? note : null,
  );
}

/// Why a typed reading was refused, as a key in assets/translations.
String simplifiedInvalidReadingKey(SimplifiedReading? reading) =>
    reading?.kind == MeasurementKind.bp
    ? 'simplified_mode.invalid_bp'
    : 'measurements.invalid_reading';
