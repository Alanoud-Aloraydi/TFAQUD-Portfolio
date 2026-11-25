import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
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

/// «وقت أخذ الجرعة» of «سجّل جرعة الآن»: the [time] shown, and the time
/// sheet to pick another.
class ExtraDoseTimeGroup extends StatelessWidget {
  const ExtraDoseTimeGroup({
    super.key,
    required this.time,
    required this.onPicked,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: <Widget>[
      InsetRow(
        label: context.tr('medications.dose_now_time'),
        value: timeOfDayText(time),
        onTap: () async {
          final TimeOfDay? selected = await showTafaqodTimeSheet(
            context,
            title: context.tr('medications.dose_now_time'),
            initialTime: time,
          );
          if (selected != null && context.mounted) onPicked(selected);
        },
      ),
    ],
  );
}
