import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_leading.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_body.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A medicine in «السجل»: its plan status and start, a revision waiting, the
/// last explicit dose, and a tap that opens its full record.
class MedicationRecordCard extends StatelessWidget {
  const MedicationRecordCard({
    super.key,
    required this.circleId,
    required this.plan,
  });

  final String circleId;
  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    final today = PatientClockScope.of(context).today();
    return RecordItemCard(
      leading: MedicationLeading(circleId: circleId, planId: plan.id),
      title: DoseStrengthLine(
        name: version.name,
        strengthValue: version.strengthValue,
        strengthUnit: version.strengthUnit,
      ),
      subtitle: Text(
        formatStartDate(context, version.startsOn, today: today),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      status: PlanStatusBadge(plan.statusOn(today)),
      onTap: () => context.push(
        Routes.medicationDetails(circleId, plan.id),
        extra: false,
      ),
      body: medicationRecordBody(context, circleId: circleId, plan: plan),
    );
  }
}
