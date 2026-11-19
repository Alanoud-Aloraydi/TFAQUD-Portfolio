import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:flutter/material.dart';

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
