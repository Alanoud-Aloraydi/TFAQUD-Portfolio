import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/today_medication_view.dart';
import 'package:flutter_test/flutter_test.dart';

// The patient's wall clock, midday of 11 November.
final DateTime _now = DateTime.utc(2026, 11, 11, 12);

DoseOccurrence _dose(int day, {DoseRecord? record}) => DoseOccurrence(
  planId: 'p-1',
  scheduleId: 's-$day',
  name: 'ميتفورمين',
  scheduledOn: DateTime(2026, 11, day),
  time: '08:00',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  record: record,
  missedAfterMinutes: 120,
);

void main() {
  group('TodayMedicationView.attention', () {
    test('holds missed doses from two days back, oldest day first', () {
      final view = TodayMedicationView([_dose(9), _dose(10), _dose(11)], _now);

      expect(view.attention.map((item) => item.scheduledOn.day), [9, 10, 11]);
    });

    test('drops doses older than two days', () {
      final view = TodayMedicationView([_dose(8), _dose(7)], _now);

      expect(view.attention, isEmpty);
    });

    test('drops a dose that was recorded late', () {
      final record = DoseRecord(
        id: 'r-1',
        outcome: DoseOutcome.taken,
        takenAt: DateTime.utc(2026, 11, 11, 9),
        recordedAt: DateTime.utc(2026, 11, 11, 9),
      );
      final view = TodayMedicationView([_dose(9, record: record)], _now);

      expect(view.attention, isEmpty);
    });
  });
}
