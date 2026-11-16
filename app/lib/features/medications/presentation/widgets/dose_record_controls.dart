import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_recording_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_regular_controls.dart';
import 'package:app/features/medications/presentation/widgets/snooze_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Defines the supported dose controls layout values.
enum DoseControlsLayout { regular, today, attention }

/// The answers to one unrecorded dose («انأخذت», another time, skip,
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
    final record = occurrence.record;
    if (record != null) {
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
      // One button system for every task (TaskButtonRole): each answer its
      // own color and icon, all 48 high, two to a line of equal widths.
      String say(String key) => CareVoice.tr(context, circleId, key);
      return TaskButtonGrid(
        buttons: <Widget>[
          if (isToday)
            // A day of four doses shows four «انأخذت»: read aloud they are
            // the same word, so the reader is told which medicine.
            TaskButton(
              role: TaskButtonRole.answer,
              icon: CupertinoIcons.checkmark,
              label: say('medications.taken_short'),
              semanticLabel:
                  '${say('medications.taken_short')}، ${occurrence.name}',
              onPressed: () =>
                  takeDoseNow(context, occurrence, circleId: circleId),
            ),
          if (isToday && circleId != null)
            SnoozeButton(occurrence: occurrence, circleId: circleId!),
          TaskButton(
            role: TaskButtonRole.earlier,
            icon: CupertinoIcons.clock,
            label: say('medications.different_time_short'),
            onPressed: () => takeDoseAtDifferentTime(
              context,
              occurrence,
              circleId: circleId,
            ),
          ),
          TaskButton(
            role: TaskButtonRole.skip,
            icon: CupertinoIcons.minus_circle,
            label: context.tr('medications.skip_short'),
            onPressed: () => skipDose(context, occurrence, circleId: circleId),
          ),
        ],
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
