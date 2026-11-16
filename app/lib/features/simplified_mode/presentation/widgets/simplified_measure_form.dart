import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_field.dart';
import 'package:flutter/material.dart';

/// What the patient has typed on «تسجيل قياس»: the numbers, the chosen
/// circumstances, the note and the message under the number. The screen
/// keeps one of these and redraws after every change.
class SimplifiedMeasureForm {
  MeasurementKind? kind;

  /// Whether the first load chose the kind and its starting conditions.
  bool started = false;
  final Map<SimplifiedMeasureField, String> values =
      <SimplifiedMeasureField, String>{
        for (final SimplifiedMeasureField field
            in SimplifiedMeasureField.values)
          field: '',
      };
  SimplifiedMeasureField upperOrLower = SimplifiedMeasureField.upper;

  /// «ظروف القياس» chosen; a task's start as its plan gives them, the same
  /// as the detailed mode's reading sheet.
  List<String> conditions = const <String>[];
  final TextEditingController note = TextEditingController();
  String? errorKey;

  SimplifiedMeasureField get active => kind == MeasurementKind.glucose
      ? SimplifiedMeasureField.glucose
      : upperOrLower;

  void type(String digit) {
    final String current = values[active]!;
    if (current.length < 3) values[active] = current + digit;
    errorKey = null;
  }

  void erase() {
    final String current = values[active]!;
    if (current.isNotEmpty) {
      values[active] = current.substring(0, current.length - 1);
    }
    errorKey = null;
  }

  /// Shows [next], starting its conditions from the task when there is one.
  void show(SimplifiedMeasurementState state, MeasurementKind? next) {
    kind = next;
    conditions = state.task?.measurementState == null
        ? const <String>[]
        : <String>[state.task!.measurementState!];
    errorKey = null;
  }
}
