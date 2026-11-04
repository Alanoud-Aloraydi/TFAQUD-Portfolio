import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_card.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Displays the medication plan list UI.
class MedicationPlanList extends StatelessWidget {
  const MedicationPlanList({
    super.key,
    this.title,
    required this.emptyText,
    required this.plans,
    required this.circleId,
    this.shrinkWrap = false,
    this.header,
  });

  /// The section title. Null when something above already names the list,
  /// such as the record tab's filter.
  final String? title;
  final String emptyText;
  final List<MedicationPlan> plans;
  final String circleId;
  final bool shrinkWrap;

  /// Shown above the title, such as the tab's large title.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ?header,
      if (title != null) ...[
        Text(title!, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
      ],
      if (plans.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppSemanticColors.surfacePlan,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: const Icon(TafaqodPhosphorIcons.pill),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(emptyText, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr('medications.add_from_plus'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        )
      else
        for (final plan in plans) ...[
          MedicationPlanCard(circleId: circleId, plan: plan),
          const SizedBox(height: AppSpacing.md),
        ],
    ];
    if (shrinkWrap) return Column(children: children);
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: children,
    );
  }
}
