import 'package:app/features/measurements/domain/entities/measurement_kind.dart';

/// The message for numbers `MeasurementLimits` refuses, about [kind] only:
/// a blood pressure's two ranges, or the sugar's. Both modes show it under
/// the numbers.
String invalidReadingKey(MeasurementKind kind) =>
    kind == MeasurementKind.glucose
    ? 'measurements.invalid_glucose'
    : 'measurements.invalid_pressure';

/// Whether [key] is one of the messages of [invalidReadingKey].
bool isInvalidReadingKey(String? key) =>
    key == 'measurements.invalid_glucose' ||
    key == 'measurements.invalid_pressure';
