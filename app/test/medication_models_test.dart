import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/features/medications/data/models/dose_occurrence_model.dart';
import 'package:app/features/medications/data/models/medication_plan_model.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  test('plan response maps its schedules and milliliter unit', () {
    final plan = MedicationPlanModel.fromJson({
      'id': 'plan-1',
      'created_at': '2026-10-01T10:00:00Z',
      'discontinued_at': null,
      'history': [
        {
          'version_number': 1,
          'name': 'Medicine',
          'strength_value': '5',
          'strength_unit': 'mg',
          'dosage_form': 'liquid',
          'treatment_starts_on': '2026-10-01',
          'effective_from_on': '2026-10-01',
          'schedules': [],
        },
      ],
      'last_record': {
        'outcome': 'taken',
        'scheduled_on': '2026-10-27',
        'time_of_day': '08:00',
        'taken_at': '2026-10-27T05:05:00Z',
      },
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
    expect(plan.history.single.number, 1);
    expect(plan.version.schedules.single.weekdays, [1, 3, 5]);
    expect(plan.lastRecord!.outcome, DoseOutcome.taken);
    expect(plan.lastRecord!.scheduledOn.day, 27);
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

  test('Arabic and Persian numeric input is stored as Western digits', () {
    const formatter = WesternDigitsFormatter(decimal: true);
    final formatted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '\u0665\u0660\u066B\u06F5',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    expect(formatted.text, '50.5');
    expect(formatted.selection.baseOffset, 4);

    final data = MedicationFormData(null);
    addTearDown(data.dispose);
    data.name.text = 'Medicine';
    data.strength.text = '\u0665\u0660\u066B\u06F5';
    data.schedules.single.doseController.text = '\u06F2\u066B\u0665';
    expect(data.firstIssue(), isNull);
    expect(data.toDraft()!.strengthValue, 50.5);
    expect(data.toDraft()!.schedules.single.doseValue, 2.5);
  });

  group('monthly schedules', () {
    Map<String, dynamic> schedule(Map<String, dynamic> changes) => {
      'id': 'schedule-1',
      'time_of_day': '08:00',
      'dose_value': '1',
      'dose_unit': 'tablet',
      'instructions': null,
      'weekdays': <int>[],
      ...changes,
    };

    MedicationSchedule parse(Map<String, dynamic> schedule) =>
        MedicationPlanModel.fromJson({
          'id': 'plan-1',
          'created_at': '2026-10-01T10:00:00Z',
          'discontinued_at': null,
          'history': [],
          'version': {
            'version_number': 1,
            'name': 'Medicine',
            'strength_value': '5',
            'strength_unit': 'mg',
            'dosage_form': 'tablet',
            'reason_for_use': null,
            'instructions': null,
            'treatment_starts_on': '2026-10-01',
            'treatment_ends_on': null,
            'effective_from_on': '2026-10-01',
            'effective_until_on': null,
            'schedules': [schedule],
          },
        }).toEntity().version.schedules.single;

    test('a monthly schedule keeps its days of the month', () {
      final MedicationSchedule value = parse(
        schedule({
          'repeat': 'monthly',
          'month_days': [1, 15],
        }),
      );

      expect(value.repeat, ScheduleRepeat.monthly);
      expect(value.monthDays, [1, 15]);
      expect(value.weekdays, isEmpty);
    });

    test('an older server without repeat is weekly', () {
      final MedicationSchedule value = parse(
        schedule({
          'weekdays': [1, 3],
        }),
      );

      expect(value.repeat, ScheduleRepeat.weekly);
      expect(value.monthDays, isEmpty);
    });

    test('a weekly draft is sent as before, a monthly one names it', () {
      final Map<String, Object?> weekly = MedicationScheduleDraft(
        time: '08:00',
        doseValue: 1,
        doseUnit: DoseUnit.tablet,
        weekdays: const [1, 2],
      ).toJson();
      final Map<String, Object?> monthly = MedicationScheduleDraft(
        time: '08:00',
        doseValue: 1,
        doseUnit: DoseUnit.tablet,
        weekdays: const [],
        repeat: ScheduleRepeat.monthly,
        monthDays: const [5, 31],
      ).toJson();

      expect(weekly.containsKey('repeat'), isFalse);
      expect(weekly.containsKey('month_days'), isFalse);
      expect(weekly['weekdays'], [1, 2]);
      expect(monthly['repeat'], 'monthly');
      expect(monthly['month_days'], [5, 31]);
      expect(monthly['weekdays'], isEmpty);
    });

    test('the form asks for a day of the month and sends only those', () {
      final data = MedicationFormData(null);
      addTearDown(data.dispose);
      data.name.text = 'Medicine';
      data.strength.text = '5';
      final schedule = data.schedules.single..repeat = ScheduleRepeat.monthly;

      expect(data.firstIssue()!.field, MedicationFormField.weekdays);

      schedule.monthDays.addAll({31, 1});
      final MedicationScheduleDraft draft = data.toDraft()!.schedules.single;
      expect(draft.repeat, ScheduleRepeat.monthly);
      expect(draft.monthDays, [1, 31]);
      expect(draft.weekdays, isEmpty);
      // The weekdays stay in the form, for switching back.
      expect(schedule.weekdays, {1, 2, 3, 4, 5, 6, 7});
    });
  });
}
