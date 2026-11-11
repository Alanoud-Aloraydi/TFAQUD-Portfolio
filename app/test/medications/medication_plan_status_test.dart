import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan_status.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 11, 10);

MedicationPlan _plan({
  required DateTime effectiveFromOn,
  DateTime? endsOn,
  DateTime? stoppedAt,
}) => MedicationPlan(
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
    effectiveFromOn: effectiveFromOn,
    schedules: const <MedicationSchedule>[],
  ),
);

void main() {
  group('MedicationPlanStatus', () {
    test('a plan in effect is active', () {
      final MedicationPlan plan = _plan(effectiveFromOn: DateTime(2026, 10, 1));
      expect(plan.statusOn(_today), PlanStatus.active);
    });

    test('a plan that starts later is scheduled', () {
      final MedicationPlan plan = _plan(
        effectiveFromOn: DateTime(2026, 11, 12),
      );
      expect(plan.statusOn(_today), PlanStatus.scheduled);
    });

    test('a plan past its end date is completed', () {
      final MedicationPlan plan = _plan(
        effectiveFromOn: DateTime(2026, 10, 1),
        endsOn: DateTime(2026, 11, 9),
      );
      expect(plan.statusOn(_today), PlanStatus.completed);
    });

    test('the end day itself is still active', () {
      final MedicationPlan plan = _plan(
        effectiveFromOn: DateTime(2026, 10, 1),
        endsOn: _today,
      );
      expect(plan.statusOn(_today), PlanStatus.active);
    });

    test('a plan stopped early is stopped, even past its end date', () {
      final MedicationPlan plan = _plan(
        effectiveFromOn: DateTime(2026, 10, 1),
        endsOn: DateTime(2026, 11, 9),
        stoppedAt: DateTime.utc(2026, 11, 1),
      );
      expect(plan.statusOn(_today), PlanStatus.stopped);
    });
  });
}
