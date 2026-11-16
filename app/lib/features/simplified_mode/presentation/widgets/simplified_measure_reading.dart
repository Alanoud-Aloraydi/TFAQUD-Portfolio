import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_field.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';

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
