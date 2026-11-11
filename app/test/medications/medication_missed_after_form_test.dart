import 'package:app/core/constants/plan_limits.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 11, 10);

MedicationFormData _filled() {
  final data = MedicationFormData(null, today: _today);
  data.name.text = 'Medicine';
  data.strength.text = '5';
  data.schedules.single.doseController.text = '1';
  return data;
}

void main() {
  group('MedicationFormData missed-after minutes', () {
    test('starts on the default of 60 minutes', () {
      final data = _filled();
      addTearDown(data.dispose);
      expect(data.missedAfterMinutes, PlanLimits.defaultMissedAfterMinutes);
      expect(data.firstIssue(), isNull);
    });

    test('any minutes inside the range are sent as typed', () {
      final data = _filled();
      addTearDown(data.dispose);
      data.missedAfterMinutes = 45;
      expect(data.firstIssue(), isNull);
      expect(data.toDraft()!.missedAfterMinutes, 45);
    });

    test('minutes outside the range, or none, are an issue', () {
      final data = _filled();
      addTearDown(data.dispose);
      for (final int? minutes in <int?>[null, 4, 361]) {
        data.missedAfterMinutes = minutes;
        expect(data.firstIssue()!.field, MedicationFormField.missedAfter);
        expect(data.toDraft(), isNull);
      }
    });
  });
}
