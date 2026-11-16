import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

/// The largest dose the stepper reaches.
const double maxDose = 999;

/// Half a tablet and half a millilitre are common; the other units count
/// whole capsules, drops, puffs and units.
double doseStep(DoseUnit unit) => switch (unit) {
  DoseUnit.tablet || DoseUnit.milliliter => 0.5,
  _ => 1,
};

/// The dose typed in the field, in western digits, or null while it is not
/// a number yet.
double? typedDose(String text) =>
    double.tryParse(ArabicDigits.toWesternDecimal(text.trim()));

/// One step up or down, on the step's grid: 1.2 tablets goes to 1.5 or 1.
double steppedDose(double? current, int direction, double step) {
  final double raw = (current ?? 0) + direction * step;
  return ((raw / step).round() * step).clamp(step, maxDose);
}
