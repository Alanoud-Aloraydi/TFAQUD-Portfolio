import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/home_add_plan_option.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The plans offered in the add sheet, in order. A plan whose callback is
/// null is left out, because the account may not edit that area.
List<Widget> homeAddPlanOptions(
  BuildContext context, {
  required String circleId,
  required VoidCallback? onMedication,
  required VoidCallback? onMeasurement,
  required VoidCallback? onAppointment,
}) => <Widget>[
  if (onMedication case final VoidCallback open)
    HomeAddPlanOption(
      icon: CareIcons.pill,
      title: context.tr('add.medication'),
      hint: CareVoice.tr(context, circleId, 'add.medication_hint'),
      onTap: open,
    ),
  if (onMeasurement case final VoidCallback open)
    HomeAddPlanOption(
      icon: CareIcons.listPlus,
      title: context.tr('add.measurement'),
      hint: context.tr('add.measurement_hint'),
      onTap: open,
    ),
  if (onAppointment case final VoidCallback open)
    HomeAddPlanOption(
      icon: ScheduleIcons.calendarPlus,
      title: context.tr('add.appointment'),
      hint: context.tr('add.appointment_hint'),
      onTap: open,
    ),
];

/// The [plans] with a line between each two of them.
List<Widget> homeAddPlanRows(List<Widget> plans) => <Widget>[
  for (int i = 0; i < plans.length; i++) ...<Widget>[
    if (i > 0) const HomeAddRowDivider(),
    plans[i],
  ],
];

/// The line between two plans, from the start of their text.
class HomeAddRowDivider extends StatelessWidget {
  const HomeAddRowDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: AppSizes.divider,
    indent: AppSpacing.lg + AppSizes.avatar + AppSpacing.md,
    color: AppSemanticColors.textPrimary.withValues(alpha: 0.08),
  );
}
