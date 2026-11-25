import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan_draft.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading_draft.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Saves the reading the sheet describes and closes it.
mixin MeasurementReadingSheetSaving on MeasurementReadingSheetScope {
  Future<void> save() async {
    final one = int.tryParse(
      kind == MeasurementKind.bp ? systolic.text : glucose.text,
    );
    final two = kind == MeasurementKind.bp
        ? int.tryParse(diastolic.text)
        : null;
    if (one == null || !MeasurementLimits.reading(kind, one, two)) {
      setState(() => errorKey = 'measurements.invalid_reading');
      return;
    }
    // The time read is the patient's wall clock where they live, wherever
    // this phone is: the latest such time, so last night's after midnight.
    final PatientClock clock = PatientClockScope.of(context);
    final measuredAt = latestReadingMoment(
      clock,
      '${time.hour}:${time.minute}',
    );
    final draft = MeasurementReadingDraft(
      kind: kind,
      outcome: 'read',
      measuredAt: measuredAt,
      valueOne: one,
      valueTwo: two,
      conditions: conditions,
      otherCondition:
          conditions.contains('other') && otherCondition.text.trim().isNotEmpty
          ? otherCondition.text.trim()
          : null,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
    );
    setState(() {
      saving = true;
      errorKey = null;
    });
    final String? failure = await context
        .read<MeasurementReadingsCubit>()
        .record(draft, clock: clock, occurrence: widget.occurrence);
    if (!mounted) return;
    if (failure == null) {
      // Read before the sheet closes: its own messenger goes with it.
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final String saved = context.tr('toast.reading_saved');
      Navigator.of(context).pop(true);
      AppToast.showText(messenger, saved);
    } else {
      setState(() {
        saving = false;
        errorKey = failure;
      });
    }
  }
}
