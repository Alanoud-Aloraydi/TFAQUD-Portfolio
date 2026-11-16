import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_conditions.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_hint.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_keypad.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_values.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_segmented.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The form of «تسجيل قياس»: the kind to record when there is a choice,
/// the typed number, the hint under it, the keypad, and the circumstances.
List<Widget> simplifiedMeasureFormRows(
  BuildContext context,
  SimplifiedMeasurementState state,
  SimplifiedMeasureForm form,
  MeasurementKind kind, {
  required VoidCallback onChanged,
}) => <Widget>[
  if (state.kinds.length > 1)
    SimplifiedSegmented<MeasurementKind>(
      segments: <MeasurementKind, String>{
        for (final MeasurementKind item in state.kinds)
          item: context.tr('measurements.${item.name}'),
      },
      selected: kind,
      onChanged: (value) {
        form.show(state, value);
        onChanged();
      },
    ),
  simplifiedMeasureValues(
    context,
    form,
    glucose: kind == MeasurementKind.glucose,
    onPick: (field) {
      form.upperOrLower = field;
      onChanged();
    },
  ),
  simplifiedMeasureHint(context, form, kind),
  SimplifiedMeasureKeypad(
    onDigit: (digit) {
      form.type(digit);
      onChanged();
    },
    onErase: () {
      form.erase();
      onChanged();
    },
  ),
  simplifiedMeasureConditions(context, form, kind: kind, onChanged: onChanged),
];
