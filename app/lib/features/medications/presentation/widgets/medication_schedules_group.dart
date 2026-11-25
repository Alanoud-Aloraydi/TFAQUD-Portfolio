import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «مواعيد الجرعات»: the dose times of the form, with the row that adds one,
/// and while there are none, what that means.
class MedicationSchedulesGroup extends StatelessWidget {
  const MedicationSchedulesGroup({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('medications.dose_schedules'),
      footer: state.data.schedules.isEmpty
          ? context.tr('medications.no_schedules_hint')
          : null,
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

/// The dose times of the form, each editable and removable: a medicine can
/// keep none.
List<Widget> medicationScheduleList(MedicationFormState state) {
  final MedicationFormData data = state.data;
  return <Widget>[
    for (var index = 0; index < data.schedules.length; index++)
      MedicationScheduleEditor(
        index: index,
        data: data.schedules[index],
        units: data.form.doseUnits,
        issue: state.issue?.scheduleIndex == index ? state.issue : null,
        startsOn: data.startsOn,
        onChanged: state.changed,
        onRemove: () {
          data.removeSchedule(index);
          state.changed();
        },
      ),
  ];
}
