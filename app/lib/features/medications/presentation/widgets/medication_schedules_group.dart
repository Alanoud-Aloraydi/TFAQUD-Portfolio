import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «أوقات الجرعات»: the dose times of the form, with the row that adds one.
class MedicationSchedulesGroup extends StatelessWidget {
  const MedicationSchedulesGroup({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('medications.dose_schedules'),
      children: [
        ...medicationScheduleList(state),
        InsetRow(
          label: context.tr('medications.add_schedule'),
          leading: const Icon(ActionIcons.plusCircle),
          onTap: () {
            state.data.addSchedule();
            state.changed();
          },
        ),
      ],
    );
  }
}
