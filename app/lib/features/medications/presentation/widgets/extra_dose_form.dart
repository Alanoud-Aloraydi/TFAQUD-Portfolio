import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_fields.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_lines.dart';
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
