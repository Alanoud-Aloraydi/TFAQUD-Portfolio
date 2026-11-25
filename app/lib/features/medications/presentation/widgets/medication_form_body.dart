import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
import 'package:app/features/medications/presentation/widgets/medication_effective_chips.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_medicine.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_instructions_group.dart';
import 'package:app/features/medications/presentation/widgets/medication_period_fields.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the form asks for, top to bottom: the medicine itself with its
/// photo, its dose times, the day a change takes over, the instructions,
/// and the treatment period.
class MedicationFormBody extends StatelessWidget {
  const MedicationFormBody({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    final bool startInPast = state.errorKey == 'medications.start_in_past';
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicationFormMedicine(state: state),
          const SizedBox(height: AppSpacing.xl),
          MedicationSchedulesGroup(state: state),
          if (state.widget.plan != null && state.medicalFieldsDirty) ...[
            const SizedBox(height: AppSpacing.xl),
            MedicationEffectiveDateGroup(
              data: state.data,
              circleId: state.widget.circleId,
              onChanged: state.changed,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          MedicationInstructionsGroup(
            data: state.data,
            issue: state.issue,
            onChanged: state.changed,
          ),
          const SizedBox(height: AppSpacing.xl),
          MedicationPeriodFields(
            data: state.data,
            issue: state.issue,
            onChanged: state.changed,
            startError: startInPast ? state.errorKey : null,
          ),
          MedicationFormFooter(errorKey: startInPast ? null : state.errorKey),
        ],
      ),
    );
  }
}

/// The end of the medication form. Why it could not be saved ([errorKey])
/// is a toast: a refusal of a field is said under that field. Stopping a
/// medicine is not here: it is in the medicine's details on its card, with
/// the stop of a measurement plan and the cancel of a visit.
class MedicationFormFooter extends StatelessWidget {
  const MedicationFormFooter({super.key, this.errorKey});

  final String? errorKey;

  @override
  Widget build(BuildContext context) => ErrorToast(
    errorKey: errorKey,
    child: const SizedBox(height: AppSpacing.xl),
  );
}

/// A revision starts right away or on a later selected day.
class MedicationEffectiveDateGroup extends StatelessWidget {
  const MedicationEffectiveDateGroup({
    super.key,
    required this.data,
    required this.onChanged,
    this.circleId,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  /// For the words: the patient's «جدولك» or the patient's name.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final today = PatientClockScope.of(context).today();
    final selected = data.effectiveFromOn ?? today;
    final isNow = DateUtils.isSameDay(selected, today);
    return InsetGroup(
      header: context.tr('medications.effective_question'),
      footer: CareVoice.tr(context, circleId, 'medications.effective_hint'),
      children: <Widget>[
        MedicationEffectiveChips(
          data: data,
          onChanged: onChanged,
          today: today,
          selected: selected,
          isNow: isNow,
        ),
        if (!isNow)
          MedicationDateRow(
            label: context.tr('medications.effective_from'),
            value: selected,
            firstDate: today,
            onChanged: (DateTime? date) {
              if (date == null) return;
              data.effectiveFromOn = date;
              onChanged();
            },
          ),
      ],
    );
  }
}

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
