import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/schedule_form_defaults.dart';

/// Adding and removing dose times while the form is open.
extension MedicationFormSchedules on MedicationFormData {
  /// A new dose time keeps the unit of the one before it, when that unit
  /// belongs to the form chosen.
  void addSchedule() {
    final previousUnit = schedules.isEmpty ? null : schedules.last.doseUnit;
    final unit = form.doseUnits.contains(previousUnit)
        ? previousUnit!
        : form.defaultDoseUnit;
    schedules.add(newScheduleForm(doseUnit: unit));
  }

  void removeSchedule(int index) => schedules.removeAt(index).dispose();
}
