import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_lines.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The fields of «سجّل جرعة الآن» once the medicines are in: which one,
/// how much, and when it was taken.
class ExtraDoseForm extends StatefulWidget {
  const ExtraDoseForm({super.key, required this.circleId, required this.plans});

  final String circleId;

  /// The medicines taken today, at least one.
  final List<MedicationPlan> plans;

  @override
  State<ExtraDoseForm> createState() => ExtraDoseFormState();
}

/// The state of [ExtraDoseForm]: what it holds and how it is sent, each in
/// its own mixin, and the fields it builds.
class ExtraDoseFormState extends State<ExtraDoseForm>
    with ExtraDoseFormScope, ExtraDoseSaving {
  @override
  Widget build(BuildContext context) {
    final TimeOfDay time =
        picked ?? TimeOfDay.fromDateTime(PatientClockScope.of(context).now());
    return ExtraDoseFields(
      circleId: widget.circleId,
      plans: widget.plans,
      plan: plan,
      dose: dose,
      time: time,
      doseError: showErrors && doseValue == null,
      missingKey: showErrors && plan == null
          ? 'medications.dose_now_choose'
          : null,
      onChoose: (chosen) => changed(() {
        plan = chosen;
        dose.doseUnit = ExtraDoseFormScope.unitOf(chosen);
      }),
      onDoseChanged: () => changed(() {}),
      onTimePicked: (value) => changed(() => picked = value),
      onSave: () => save(time),
    );
  }
}

/// Sends the extra dose the sheet describes and closes it; with something
/// missing, shows what instead.
mixin ExtraDoseSaving on ExtraDoseFormScope {
  Future<void> save(TimeOfDay time) async {
    final MedicationPlan? chosen = plan;
    final double? value = doseValue;
    if (chosen == null || value == null) {
      setState(() => showErrors = true);
      return;
    }
    // The patient's wall clock where they live: the latest such time, so
    // last night's after midnight.
    final PatientClock clock = PatientClockScope.of(context);
    final ExtraDoseDraft draft = ExtraDoseDraft(
      planId: chosen.id,
      takenAt: latestReadingMoment(clock, '${time.hour}:${time.minute}'),
      doseValue: value,
      doseUnit: dose.doseUnit,
    );
    // Read before the sheet closes: its own messenger goes with it.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String saved = context.tr('toast.dose_saved');
    if (!await context.read<ExtraDoseCubit>().record(draft)) return;
    if (!mounted) return;
    Navigator.of(context).pop(true);
    AppToast.showText(messenger, saved);
  }
}

/// «سجّل جرعة الآن» laid out: the medicines, then, once one is chosen,
/// how much and when, then the save button.
class ExtraDoseFields extends StatelessWidget {
  const ExtraDoseFields({
    super.key,
    required this.circleId,
    required this.plans,
    required this.plan,
    required this.dose,
    required this.time,
    required this.doseError,
    required this.missingKey,
    required this.onChoose,
    required this.onDoseChanged,
    required this.onTimePicked,
    required this.onSave,
  });

  final String circleId;
  final List<MedicationPlan> plans;
  final MedicationPlan? plan;
  final ScheduleFormData dose;
  final TimeOfDay time;
  final bool doseError;

  /// What stops the save in the sheet itself: a key in assets/translations.
  final String? missingKey;
  final ValueChanged<MedicationPlan> onChoose;
  final VoidCallback onDoseChanged;
  final ValueChanged<TimeOfDay> onTimePicked;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final MedicationPlan? chosen = plan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExtraDoseMedicines(
          circleId: circleId,
          plans: plans,
          chosenId: chosen?.id,
          onChoose: onChoose,
        ),
        if (chosen != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ExtraDoseAmountGroup(
            plan: chosen,
            dose: dose,
            onChanged: onDoseChanged,
            showError: doseError,
          ),
          const SizedBox(height: AppSpacing.lg),
          ExtraDoseTimeGroup(time: time, onPicked: onTimePicked),
        ],
        ExtraDoseSaveButton(onPressed: onSave, missingKey: missingKey),
      ],
    );
  }
}

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

/// «حفظ الجرعة», off while the dose is on its way, with why the last try
/// was not saved above it.
class ExtraDoseSaveButton extends StatelessWidget {
  const ExtraDoseSaveButton({
    super.key,
    required this.onPressed,
    this.missingKey,
  });

  final VoidCallback onPressed;

  /// What is missing in the sheet itself: a key in assets/translations.
  final String? missingKey;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ExtraDoseCubit, ExtraDoseState>(
        builder: (BuildContext context, ExtraDoseState state) {
          final String? errorKey = missingKey ?? state.errorKey;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (errorKey != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                InlineError(messageKey: errorKey),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: state.saving ? null : onPressed,
                child: Text(context.tr('medications.dose_now_save')),
              ),
            ],
          );
        },
      );
}

/// «كمية الجرعة» of «سجّل جرعة الآن», in the units [plan]'s form is taken
/// in.
class ExtraDoseAmountGroup extends StatelessWidget {
  const ExtraDoseAmountGroup({
    super.key,
    required this.plan,
    required this.dose,
    required this.onChanged,
    required this.showError,
  });

  final MedicationPlan plan;
  final ScheduleFormData dose;
  final VoidCallback onChanged;

  /// Save was tapped while the dose is not a number above zero.
  final bool showError;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: <Widget>[
      MedicationDoseRow(
        data: dose,
        units: plan.version.dosageForm.doseUnits,
        onChanged: onChanged,
        issue: showError
            ? const MedicationFormIssue(MedicationFormField.dose)
            : null,
      ),
    ],
  );
}
