import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_fields.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_form.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_form_scope.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_saving.dart';
import 'package:flutter/material.dart';

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
