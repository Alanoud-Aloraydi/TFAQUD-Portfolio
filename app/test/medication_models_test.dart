import 'package:app/features/medications/data/models/dose_occurrence_model.dart';
import 'package:app/features/medications/data/models/medication_plan_model.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plan response maps its schedules and milliliter unit', () {
    final plan = MedicationPlanModel.fromJson({
      'id': 'plan-1',
      'created_at': '2026-10-01T10:00:00Z',
      'discontinued_at': null,
      'version': {
        'version_number': 1,
        'name': 'Medicine',
        'strength_value': '5',
        'strength_unit': 'mg',
        'dosage_form': 'liquid',
        'reason_for_use': null,
        'instructions': null,
        'treatment_starts_on': '2026-10-01',
        'treatment_ends_on': null,
        'effective_from_on': '2026-10-01',
        'effective_until_on': null,
        'schedules': [
          {
            'id': 'schedule-1',
            'time_of_day': '08:00',
            'dose_value': '2.5',
            'dose_unit': 'mL',
            'instructions': null,
            'weekdays': [1, 3, 5],
          },
        ],
      },
    }).toEntity();

    expect(plan.version.schedules.single.doseUnit, DoseUnit.milliliter);
    expect(plan.version.schedules.single.weekdays, [1, 3, 5]);
  });

  test('dose response maps the explicit outcome timestamps', () {
    final occurrence = DoseOccurrenceModel.fromJson({
      'plan_id': 'plan-1',
      'schedule_id': 'schedule-1',
      'scheduled_on': '2026-10-27',
      'time_of_day': '08:00',
      'name': 'Medicine',
      'strength_value': '5',
      'strength_unit': 'mg',
      'dosage_form': 'tablet',
      'dose_value': '1',
      'dose_unit': 'tablet',
      'instructions': null,
      'timing_state': null,
      'record': {
        'id': 'record-1',
        'outcome': 'taken',
        'taken_at': '2026-10-27T05:05:00Z',
        'skip_reason_code': null,
        'skip_reason_note': null,
        'recorded_at': '2026-10-27T05:06:00Z',
      },
    }).toEntity();

    expect(occurrence.record!.outcome, DoseOutcome.taken);
    expect(occurrence.record!.takenAt, isNotNull);
  });

  test('form reports the first invalid field in reading order', () {
    final data = MedicationFormData(null);
    addTearDown(data.dispose);

    expect(data.firstIssue()!.field, MedicationFormField.name);
    data.name.text = 'Medicine';
    expect(data.firstIssue()!.field, MedicationFormField.strength);
    data.strength.text = '5';
    data.endsOn = data.startsOn.subtract(const Duration(days: 1));
    expect(data.firstIssue()!.field, MedicationFormField.period);
    data.endsOn = null;
    data.schedules.single.doseController.text = '0';
    expect(data.firstIssue()!.field, MedicationFormField.dose);
    data.schedules.single.doseController.text = '0.5';
    data.schedules.single.weekdays.clear();
    expect(data.firstIssue()!.field, MedicationFormField.weekdays);
  });
}
