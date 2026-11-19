import 'package:app/features/medications/data/models/extra_dose_model.dart';
import 'package:app/features/medications/domain/entities/dose_unit.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an extra dose reads the server text dose and its unit', () {
    final ExtraDose dose = extraDoseFromJson(<String, dynamic>{
      'id': 'dose',
      'plan_id': 'plan',
      'taken_at': '2026-11-19T09:30:00+00:00',
      'dose_value': '2.5',
      'dose_unit': 'mL',
      'recorded_at': '2026-11-19T09:31:00+00:00',
      'recorded_by': <String, dynamic>{
        'account_id': 'account',
        'name': 'لينا',
        'avatar_code': 'w_1',
      },
    });

    expect(dose.takenAt.toUtc(), DateTime.utc(2026, 11, 19, 9, 30));
    expect(dose.doseValue, 2.5);
    expect(dose.doseUnit, DoseUnit.milliliter);
    expect(dose.recordedByName, 'لينا');
  });

  test('a draft is sent in UTC with the dose as a number', () {
    final Map<String, Object?> body = extraDoseDraftToJson(
      ExtraDoseDraft(
        planId: 'plan',
        takenAt: DateTime.utc(2026, 11, 19, 9, 30),
        doseValue: 1,
        doseUnit: DoseUnit.milliliter,
      ),
    );

    expect(body, <String, Object?>{
      'plan_id': 'plan',
      'taken_at': '2026-11-19T09:30:00.000Z',
      'dose_value': 1.0,
      'dose_unit': 'mL',
    });
  });
}
