import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/section_header.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Displays the medication plan list UI.
class MedicationPlanList extends StatelessWidget {
  const MedicationPlanList({
    super.key,
    this.title,
    required this.emptyText,
    required this.plans,
    required this.circleId,
    required this.canManage,
    this.shrinkWrap = false,
    this.header,
    this.onAdd,
  });

  /// The section title. Null when something above already names the list,
  /// such as the record tab's filter.
  final String? title;
  final String emptyText;
  final List<MedicationPlan> plans;
  final String circleId;
  final bool canManage;
  final bool shrinkWrap;

  /// Shown above the title, such as the tab's large title.
  final Widget? header;

  /// Opens the new-plan flow; null (or [canManage] false) hides the action.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ?header,
      if (title != null) ...[
        SectionHeader(title!),
        const SizedBox(height: AppSpacing.md),
      ],
      if (plans.isEmpty)
        EmptyStateNote.section(
          emptyText,
          actionLabel: canManage ? context.tr('add.medication') : null,
          onAction: canManage ? onAdd : null,
        )
      else
        for (final plan in plans) ...[
          MedicationPlanCard(
            circleId: circleId,
            plan: plan,
            canManage: canManage,
          ),
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
