import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_moment.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_form_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
