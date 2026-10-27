import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_card.dart';
import 'package:flutter/material.dart';

class MedicationPlanList extends StatelessWidget {
  const MedicationPlanList({
    super.key,
    required this.title,
    required this.emptyText,
    required this.plans,
    required this.circleId,
    this.shrinkWrap = false,
  });

  final String title;
  final String emptyText;
  final List<MedicationPlan> plans;
  final String circleId;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.md),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: children,
    );
  }
}
