import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_validation.dart';
import 'package:app/features/medications/presentation/models/medication_form_values.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';

/// What the form sends to the server.
extension MedicationFormDraft on MedicationFormData {
  /// The medicine as typed, or null while the form still refuses something.
  MedicationPlanDraft? toDraft() {
    if (firstIssue() != null) return null;
    final strengthText = ArabicDigits.toWesternDecimal(strength.text.trim());
    return MedicationPlanDraft(
      name: name.text.trim(),
      strengthValue: double.parse(strengthText),
      strengthUnit: strengthUnit,
      dosageForm: form,
      reason: optionalText(reason.text),
      instructions: optionalText(instructions.text),
      missedAfterMinutes: missedAfterMinutes!,
      startsOn: startsOn,
      endsOn: endsOn,
      effectiveFromOn: effectiveFromOn,
      schedules: <MedicationScheduleDraft>[
        for (final item in schedules) _scheduleDraft(item),
      ],
    );
  }

  MedicationScheduleDraft _scheduleDraft(ScheduleFormData item) {
    final doseText = ArabicDigits.toWesternDecimal(
      item.doseController.text.trim(),
    );
    return MedicationScheduleDraft(
      time: formTimeText(item.time),
      doseValue: double.parse(doseText),
      doseUnit: item.doseUnit,
      repeat: item.repeat,
      weekdays: item.repeat == ScheduleRepeat.weekly
          ? (item.weekdays.toList()..sort())
          : const <int>[],
      intervalDays: item.repeat == ScheduleRepeat.interval
          ? item.intervalDays
          : null,
      instructions: optionalText(item.instructionsController.text),
    );
  }
}
