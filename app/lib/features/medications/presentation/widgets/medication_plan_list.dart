import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// The medicines «السجل» keeps under its filter, or the note that this
/// filter has none, with «جدولة دواء» when [canAdd].
List<Widget> medicationRecordList(
  BuildContext context, {
  required String circleId,
  required List<MedicationPlan> plans,
  bool canAdd = false,
}) {
  if (plans.isEmpty) {
    return <Widget>[
      EmptyStateNote.section(
        context.tr('medications.no_records'),
        actionLabel: canAdd ? context.tr('add.medication') : null,
        onAction: canAdd
            ? () => context.push(CareItemRoutes.newMedication(circleId))
            : null,
      ),
    ];
  }
  return <Widget>[
    for (final plan in plans) ...<Widget>[
      MedicationRecordCard(circleId: circleId, plan: plan),
      const SizedBox(height: AppItemCard.listGap),
    ],
  ];
}
