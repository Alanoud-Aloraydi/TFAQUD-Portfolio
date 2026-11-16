import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/medication_record_filter.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 11, 15);

MedicationPlan _plan({DateTime? endsOn, DateTime? stoppedAt}) => MedicationPlan(
  id: 'plan-1',
  createdAt: DateTime.utc(2026, 10, 1),
  discontinuedAt: stoppedAt,
  version: MedicationVersion(
    number: 1,
    name: 'Medicine',
    strengthValue: 5,
    strengthUnit: StrengthUnit.milligram,
    dosageForm: DosageForm.tablet,
    startsOn: DateTime(2026, 10, 1),
    endsOn: endsOn,
    effectiveFromOn: DateTime(2026, 10, 1),
    schedules: const <MedicationSchedule>[],
  ),
);

void main() {
  group('MedicationRecordFilter', () {
    final MedicationPlan running = _plan();
    final MedicationPlan ended = _plan(endsOn: DateTime(2026, 11, 1));
    final MedicationPlan stopped = _plan(stoppedAt: DateTime.utc(2026, 11, 2));

    test('all keeps every plan', () {
      for (final MedicationPlan plan in <MedicationPlan>[
        running,
        ended,
        stopped,
      ]) {
        expect(MedicationRecordFilter.all.keeps(plan, _today), isTrue);
      }
    });

    test('current keeps only the plans still running', () {
      expect(MedicationRecordFilter.current.keeps(running, _today), isTrue);
      expect(MedicationRecordFilter.current.keeps(ended, _today), isFalse);
      expect(MedicationRecordFilter.current.keeps(stopped, _today), isFalse);
    });

    test('previous keeps the ended and the stopped ones', () {
      expect(MedicationRecordFilter.previous.keeps(running, _today), isFalse);
      expect(MedicationRecordFilter.previous.keeps(ended, _today), isTrue);
      expect(MedicationRecordFilter.previous.keeps(stopped, _today), isTrue);
    });

    test('every filter names its words', () {
      for (final MedicationRecordFilter value
          in MedicationRecordFilter.values) {
        expect(value.labelKey, 'medications.filter.${value.name}');
      }
    });
  });
}
