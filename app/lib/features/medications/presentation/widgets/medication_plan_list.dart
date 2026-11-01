import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_card.dart';
import 'package:flutter/material.dart';

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
          child: Center(child: Text(emptyText)),
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
