import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_controls_layout.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_recording_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_regular_controls.dart';
import 'package:app/features/medications/presentation/widgets/dose_task_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The answers to one unrecorded dose («تم أخذها», another time, skip,
/// «ذكّرني لاحقًا»), or its recorded status. Calls the nearest
/// [MedicationOccurrencesCubit] and shows a refused answer's message.
class DoseRecordControls extends StatelessWidget {
  const DoseRecordControls({
    super.key,
    required this.occurrence,
    this.layout = DoseControlsLayout.regular,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final DoseControlsLayout layout;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    if (occurrence.record != null) {
      return DoseRecordedStatus(occurrence: occurrence, circleId: circleId);
    }
    final isRecording = context.select<MedicationOccurrencesCubit, bool>(
      (cubit) => cubit.state.recordingOccurrence == occurrence,
    );
    if (isRecording) return const DoseRecordingStatus();
    final today = PatientClockScope.of(context).today();
    final scheduledOn = scheduleDay(occurrence.scheduledOn);
    if (scheduledOn.isAfter(today)) return const SizedBox.shrink();
    final isToday = scheduledOn == today;
    if (layout != DoseControlsLayout.regular) {
      return DoseTaskButtons(
        occurrence: occurrence,
        isToday: isToday,
        circleId: circleId,
      );
    }
    return doseRegularControls(
      context,
      occurrence: occurrence,
      isToday: isToday,
      circleId: circleId,
    );
  }
}
