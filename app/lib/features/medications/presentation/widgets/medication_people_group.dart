import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// «الأشخاص»: who added the medicine and who changed it last, with their
/// pictures. The last editor is left out while it is the person who added
/// it, so one name is not read twice.
Widget medicationPeopleGroup(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
}) {
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
