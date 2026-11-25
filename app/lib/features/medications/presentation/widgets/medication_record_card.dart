import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/plan_fact_group.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
import 'package:app/features/medications/presentation/widgets/medication_last_dose_box.dart';
import 'package:easy_localization/easy_localization.dart';
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
        CareItemRoutes.medicationDetails(circleId, plan.id),
        extra: false,
      ),
      body: medicationRecordBody(context, circleId: circleId, plan: plan),
    );
  }
}

/// What a medicine's record card holds under its title: the day it was last
/// revised (only for a plan that was), the last explicit dose, and the line
/// that says the card opens the full record.
List<Widget> medicationRecordBody(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
}) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    if (plan.history.length > 1)
      PlanInfoBox(
        child: Text(
          context.tr(
            'medications.revised_on',
            args: <String>[
              formatMedicationDate(context, plan.history.last.effectiveFromOn),
            ],
          ),
          style: text.bodySmall,
        ),
      ),
    MedicationLastDoseBox(circleId: circleId, last: plan.lastRecord),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(context.tr('medications.full_record'), style: text.labelMedium),
        const Icon(ArrowIcons.forward, size: AppSizes.iconSmall),
      ],
    ),
  ];
}
