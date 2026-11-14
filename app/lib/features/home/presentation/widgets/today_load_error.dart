import 'dart:async';

import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The message of a failed read with «إعادة المحاولة», which reads again
/// every part that failed.
class TodayLoadError extends StatelessWidget {
  const TodayLoadError({
    super.key,
    required this.messageKey,
    required this.circleId,
  });

  final String messageKey;
  final String circleId;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(context.tr(messageKey), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => _retry(context),
          child: Text(context.tr('auth.retry')),
        ),
      ],
    ),
  );

  void _retry(BuildContext context) {
    final doses = context.read<MedicationOccurrencesCubit>();
    final tasks = context.read<MeasurementTasksCubit>();
    final readings = context.read<MeasurementReadingsCubit>();
    final appointments = context.read<AppointmentsCubit>();
    final prayers = context.read<PrayerTimesCubit>();
    if (doses.state.status == MedicationOccurrencesStatus.failure) {
      unawaited(doses.reload());
    }
    if (tasks.state.status == MeasurementLoadStatus.failure) {
      unawaited(tasks.reload());
    }
    if (readings.state.status == MeasurementLoadStatus.failure) {
      unawaited(readings.reload());
    }
    if (appointments.state.status == AppointmentsLoadStatus.failure) {
      unawaited(appointments.load(circleId));
    }
    if (prayers.state.status == PrayerTimesStatus.failure) {
      unawaited(prayers.reload());
    }
  }
}
