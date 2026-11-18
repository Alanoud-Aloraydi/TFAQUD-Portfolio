import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// «عن الدواء»: why it is taken, how to take it, and when a dose counts as
/// missed. The reason and the instructions appear only when they were
/// written.
Widget medicationAboutGroup(BuildContext context, MedicationVersion version) {
  return PlanFactGroup(
    title: context.tr('plan_details.about_medicine'),
    children: <Widget>[
      if (version.reason case final String reason)
        PlanFact(
          icon: CareIcons.firstAid,
          label: context.tr('medications.reason'),
          value: reason,
        ),
      if (version.instructions case final String instructions)
        PlanFact(
          icon: NoticeIcons.info,
          label: context.tr('medications.instructions'),
          value: instructions,
        ),
      PlanFact(
        icon: PeopleIcons.hourglass,
        label: context.tr('medications.missed_after'),
        value: arabicCount(
          context,
          ArabicCount.minutes,
          version.missedAfterMinutes,
        ),
      ),
    ],
  );
}
