import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

final DateTime _today = DateTime(2026, 11, 15);

MedicationPlan _plan({DateTime? stoppedAt}) => MedicationPlan(
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
    effectiveFromOn: DateTime(2026, 10, 1),
    schedules: const <MedicationSchedule>[],
  ),
);

/// The stop buttons in what [plan]'s card opens.
Future<List<StopButton>> _stops(
  WidgetTester tester,
  MedicationPlan plan, {
  required bool canManage,
}) async {
  late List<Widget> details;
  await pumpArabic(
    tester,
    home: Builder(
      builder: (BuildContext context) {
        details = medicationPlanDetails(
          context,
          circleId: 'c-1',
          plan: plan,
          canManage: canManage,
          today: _today,
        );
        return const SizedBox.shrink();
      },
    ),
  );
  return details.whereType<StopButton>().toList();
}

void main() {
  setUpAll(initTestLocalization);

  group('«إيقاف الدواء» is in the medicine\'s details', () {
    testWidgets('for a manager, while the medicine runs', (tester) async {
      expect(await _stops(tester, _plan(), canManage: true), hasLength(1));
    });

    testWidgets('not for a member who does not manage medicines', (
      tester,
    ) async {
      expect(await _stops(tester, _plan(), canManage: false), isEmpty);
    });

    testWidgets('not once it was stopped', (tester) async {
      final MedicationPlan stopped = _plan(
        stoppedAt: DateTime.utc(2026, 11, 2),
      );
      expect(await _stops(tester, stopped, canManage: true), isEmpty);
    });
  });
}
