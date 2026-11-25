import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The top bar of the plan form: «إلغاء», the title of a new plan or an
/// edit, and «حفظ», which is off while [onSave] is null.
AppBar measurementPlanFormBar(
  BuildContext context, {
  required bool isNew,
  required VoidCallback? onSave,
}) => AppBar(
  automaticallyImplyLeading: false,
  centerTitle: true,
  titleSpacing: AppSpacing.lg,
  title: GlassSurface(
    borderRadius: BorderRadius.circular(AppRadius.capsule),
    child: SizedBox(
      height: 52,
      child: Row(
        children: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.tr('common.cancel')),
          ),
          Expanded(
            child: Text(
              context.tr(
                isNew ? 'measurements.new_plan' : 'measurements.edit_plan',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: FilledButton(
              onPressed: onSave,
              child: Text(context.tr('measurements.save')),
            ),
          ),
        ],
      ),
    ),
  ),
);

/// «الأشخاص» of a measurement plan: who added it and who last changed it,
/// when that was someone else, with their pictures.
class MeasurementPlanPeople extends StatelessWidget {
  const MeasurementPlanPeople({
    super.key,
    required this.plan,
    required this.circleId,
  });

  final MeasurementPlan plan;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    return PlanFactGroup(
      title: context.tr('plan_details.people'),
      children: <Widget>[
        if (plan.createdByName case final String name)
          PlanPersonFact(
            label: context.tr('medications.added_by'),
            name: name,
            circleId: circleId,
            accountId: plan.createdByAccountId,
            avatarCode: plan.createdByAvatarCode,
          ),
        if (plan.lastEditedByName case final String name
            when name != plan.createdByName)
          PlanPersonFact(
            label: context.tr('medications.last_edited_by'),
            name: name,
            circleId: circleId,
            accountId: plan.lastEditedByAccountId,
            avatarCode: plan.lastEditedByAvatarCode,
          ),
      ],
    );
  }
}
