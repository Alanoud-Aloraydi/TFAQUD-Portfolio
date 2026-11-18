import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_last_dose_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
