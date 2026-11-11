import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_plan_status.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 11, 10);

MeasurementPlan _plan({required DateTime from, DateTime? stoppedAt}) =>
    MeasurementPlan(
      id: 'plan-1',
      kind: MeasurementKind.glucose,
      stoppedAt: stoppedAt,
      history: const <MeasurementVersion>[],
      version: MeasurementVersion(
        id: 'version-1',
        number: 1,
        effectiveFromOn: from,
        time: '08:00',
        weekdays: const <int>[1, 2, 3, 4, 5, 6, 7],
        missedAfterMinutes: 60,
      ),
    );

void main() {
  group('MeasurementPlanStatus', () {
    test('a plan in effect is active', () {
      expect(
        _plan(from: DateTime(2026, 11, 1)).statusOn(_today),
        PlanStatus.active,
      );
    });

    test('a plan that starts later is scheduled', () {
      expect(
        _plan(from: DateTime(2026, 11, 11)).statusOn(_today),
        PlanStatus.scheduled,
      );
    });

    test('a stopped plan is stopped', () {
      expect(
        _plan(
          from: DateTime(2026, 11, 1),
          stoppedAt: DateTime.utc(2026, 11, 5),
        ).statusOn(_today),
        PlanStatus.stopped,
      );
    });
  });
}
