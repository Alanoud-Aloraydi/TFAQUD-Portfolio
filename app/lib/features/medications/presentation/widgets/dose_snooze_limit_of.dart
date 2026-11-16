import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// How long the dose may still be put off: 12 hours, and never past
/// halfway to the next dose of the same medicine.
Duration doseSnoozeLimitOf(BuildContext context, DoseOccurrence occurrence) {
  final PatientClock clock = PatientClockScope.of(context);
  return doseSnoozeLimit(
    occurrence,
    context.read<MedicationOccurrencesCubit>().state.occurrences,
    clock,
    DateTime.now().toUtc(),
  );
}
