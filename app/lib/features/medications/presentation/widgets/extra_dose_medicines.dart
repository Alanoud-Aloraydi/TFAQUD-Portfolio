import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_leading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الدواء» of «سجّل جرعة الآن»: one row per medicine still taken, with its
/// photo, and a tick on the one chosen.
class ExtraDoseMedicines extends StatelessWidget {
  const ExtraDoseMedicines({
    super.key,
    required this.circleId,
    required this.plans,
    required this.chosenId,
    required this.onChoose,
  });

  final String circleId;
  final List<MedicationPlan> plans;
  final String? chosenId;
  final ValueChanged<MedicationPlan> onChoose;

  @override
  Widget build(BuildContext context) => InsetGroup(
    header: context.tr('medications.dose_now_medicine'),
    children: <Widget>[
      for (final MedicationPlan plan in plans)
        InsetRow(
          label: plan.version.name,
          leading: MedicationLeading(circleId: circleId, planId: plan.id),
          trailing: plan.id == chosenId ? const Icon(ActionIcons.check) : null,
          onTap: () => onChoose(plan),
        ),
    ],
  );
}
