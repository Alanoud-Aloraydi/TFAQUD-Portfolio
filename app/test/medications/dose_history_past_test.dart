import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aspirin at 8:00 on 17 November 2026, answered with [record].
DoseOccurrence _dose({DoseRecord? record}) => DoseOccurrence(
  planId: 'p-1',
  scheduleId: 's-1',
  scheduledOn: DateTime(2026, 11, 17),
  time: '08:00',
  name: 'أسبرين',
  strengthValue: 81,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  timingState: DoseTimingState.upcoming,
  record: record,
);

void main() {
  group('«سجل الجرعات» keeps only the past', () {
    test('a dose still ahead is not history yet', () {
      // 5:09 in the morning: «موعدها لاحقًا».
      expect(_dose().isHistoryAt(DateTime.utc(2026, 11, 17, 5, 9)), isFalse);
      expect(_dose().isHistoryAt(DateTime.utc(2026, 11, 16, 23)), isFalse);
    });

    test('once its time comes it is, answered or not', () {
      expect(_dose().isHistoryAt(DateTime.utc(2026, 11, 17, 8)), isTrue);
      expect(_dose().isHistoryAt(DateTime.utc(2026, 11, 18, 9)), isTrue);
    });

    test('a dose recorded early is history at once', () {
      final DoseOccurrence taken = _dose(
        record: DoseRecord(
          id: 'r-1',
          outcome: DoseOutcome.taken,
          takenAt: DateTime.utc(2026, 11, 17, 4, 50),
          recordedAt: DateTime.utc(2026, 11, 17, 4, 50),
        ),
      );

      expect(taken.isHistoryAt(DateTime.utc(2026, 11, 17, 5, 9)), isTrue);
    });
  });
}
