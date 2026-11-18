import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
