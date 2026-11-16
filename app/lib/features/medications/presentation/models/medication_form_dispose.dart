import 'package:app/features/medications/presentation/models/medication_form_data.dart';

/// Letting go of the form's controllers and focus nodes.
extension MedicationFormDispose on MedicationFormData {
  void dispose() {
    name.dispose();
    strength.dispose();
    reason.dispose();
    instructions.dispose();
    nameFocus.dispose();
    strengthFocus.dispose();
    periodFocus.dispose();
    missedAfterFocus.dispose();
    for (final schedule in schedules) {
      schedule.dispose();
    }
  }
}
