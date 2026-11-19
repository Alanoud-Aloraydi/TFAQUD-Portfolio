import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/models/schedule_form_defaults.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_form.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What [ExtraDoseForm] holds: the medicine chosen (the only one when there
/// is one), the dose typed, the time picked (now until then), and whether
/// save was tapped with something missing.
mixin ExtraDoseFormScope on State<ExtraDoseForm> {
  late MedicationPlan? plan = widget.plans.length == 1
      ? widget.plans.single
      : null;
  late final ScheduleFormData dose = newScheduleForm(doseUnit: unitOf(plan));
  TimeOfDay? picked;
  bool showErrors = false;

  static DoseUnit unitOf(MedicationPlan? plan) =>
      plan?.version.dosageForm.defaultDoseUnit ?? DoseUnit.tablet;

  @override
  void dispose() {
    dose.dispose();
    super.dispose();
  }

  /// A dose above zero, as the server keeps it; null otherwise.
  double? get doseValue {
    final double? value = typedDose(dose.doseController.text);
    return value == null || value <= 0 || value > maxDose ? null : value;
  }

  /// A change in the sheet: the last error no longer applies.
  void changed(VoidCallback change) {
    setState(change);
    context.read<ExtraDoseCubit>().clearError();
  }
}
