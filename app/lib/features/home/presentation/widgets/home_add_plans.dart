import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
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

/// One plan: an icon tile, the name and what it does, and a chevron.
class HomeAddPlanOption extends StatelessWidget {
  const HomeAddPlanOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: spoken('$title، $hint'),
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: MergeSemantics(
          child: Row(
            children: homeAddPlanOptionRow(
              context,
              icon: icon,
              title: title,
              hint: hint,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The icon tile of a plan option.
const double _tile = AppSizes.avatar;

/// The row of one plan: the icon tile, the name and what it does, and a
/// chevron at the end.
List<Widget> homeAddPlanOptionRow(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String hint,
}) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    Container(
      width: _tile,
      height: _tile,
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Icon(
        icon,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.textSupporting,
      ),
    ),
    const SizedBox(width: AppSpacing.md),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: text.titleSmall),
          Text(
            hint,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.textSupporting,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    const Icon(
      ArrowIcons.forward,
      size: AppSizes.iconSmall,
      color: AppSemanticColors.borderControlBase,
    ),
  ];
}
