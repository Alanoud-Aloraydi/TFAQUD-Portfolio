import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_last_dose_box.dart';
import 'package:app/features/medications/presentation/widgets/medication_leading.dart';
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
    final TextTheme text = Theme.of(context).textTheme;
    return RecordItemCard(
      leading: MedicationLeading(circleId: circleId, planId: plan.id),
      title: DoseStrengthLine(
        name: version.name,
        strengthValue: version.strengthValue,
        strengthUnit: version.strengthUnit,
      ),
      subtitle: Text(
        formatStartDate(context, version.startsOn, today: today),
        style: text.bodySmall,
      ),
      status: PlanStatusBadge(plan.statusOn(today)),
      onTap: () => context.push(
        Routes.medicationDetails(circleId, plan.id),
        extra: false,
      ),
      body: <Widget>[
        if (plan.history.length > 1)
          PlanInfoBox(
            child: Text(
              context.tr(
                'medications.revised_on',
                args: <String>[
                  formatMedicationDate(
                    context,
                    plan.history.last.effectiveFromOn,
                  ),
                ],
              ),
              style: text.bodySmall,
            ),
          ),
        MedicationLastDoseBox(circleId: circleId, last: plan.lastRecord),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              context.tr('medications.full_record'),
              style: text.labelMedium,
            ),
            const Icon(AppIcons.forward, size: AppSizes.iconSmall),
          ],
        ),
      ],
    );
  }
}
