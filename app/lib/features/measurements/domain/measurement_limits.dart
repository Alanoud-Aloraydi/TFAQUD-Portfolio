import 'package:app/features/measurements/domain/measurement.dart';

/// What a reading may be. The old rule was 1 to 999 for every number, so a
/// diastolic typed as 18 instead of 80 was saved, drawn as a bar across the
/// whole chart and carried into the health summary a doctor reads. These
/// bounds are wide enough for a reading worth calling an ambulance over and
/// narrow enough to catch a slip of the finger. The backend holds the same
/// numbers in app/measurements/inputs.py; change them together.
abstract final class MeasurementLimits {
  /// The upper number of a blood pressure.
  static const int systolicLow = 60;
  static const int systolicHigh = 260;

  /// The lower number of a blood pressure.
  static const int diastolicLow = 30;
  static const int diastolicHigh = 160;

  static const int glucoseLow = 20;
  static const int glucoseHigh = 600;

  static bool glucose(int value) => value >= glucoseLow && value <= glucoseHigh;

  /// A blood pressure needs both numbers, and the upper one above the
  /// lower one.
  static bool pressure(int systolic, int diastolic) =>
      systolic >= systolicLow &&
      systolic <= systolicHigh &&
      diastolic >= diastolicLow &&
      diastolic <= diastolicHigh &&
      systolic > diastolic;

  /// Whether [one], and [two] for a blood pressure, may be saved.
  static bool reading(MeasurementKind kind, int one, int? two) =>
      kind == MeasurementKind.glucose
      ? two == null && glucose(one)
      : two != null && pressure(one, two);
}
