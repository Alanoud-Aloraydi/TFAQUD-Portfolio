import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_field.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/models/medication_form_values.dart';

/// What the form refuses, and which field to open at.
extension MedicationFormValidation on MedicationFormData {
  /// The first field that is not filled in, in the order the form reads;
  /// null when the whole form can be saved.
  MedicationFormIssue? firstIssue() {
    if (name.text.trim().isEmpty) {
      return const MedicationFormIssue(MedicationFormField.name);
    }
    final strengthText = ArabicDigits.toWesternDecimal(strength.text.trim());
    final strengthValue = isDecimalText(strengthText)
        ? double.tryParse(strengthText)
        : null;
    if (strengthValue == null || strengthValue <= 0) {
      return const MedicationFormIssue(MedicationFormField.strength);
    }
    if ((endsOn != null && endsOn!.isBefore(startsOn)) ||
        (endsOn != null &&
            effectiveFromOn != null &&
            endsOn!.isBefore(effectiveFromOn!))) {
      return const MedicationFormIssue(MedicationFormField.period);
    }
    for (var index = 0; index < schedules.length; index++) {
      final schedule = schedules[index];
      final doseText = ArabicDigits.toWesternDecimal(
        schedule.doseController.text.trim(),
      );
      final dose = isDecimalText(doseText) ? double.tryParse(doseText) : null;
      if (dose == null || dose <= 0) {
        return MedicationFormIssue(
          MedicationFormField.dose,
          scheduleIndex: index,
        );
      }
      if (!schedule.hasDays) {
        return MedicationFormIssue(
          MedicationFormField.weekdays,
          scheduleIndex: index,
        );
      }
    }
    if (!PlanLimits.isValidMissedAfter(missedAfterMinutes)) {
      return const MedicationFormIssue(MedicationFormField.missedAfter);
    }
    return null;
  }
}
