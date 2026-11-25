import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The corner of a dose in the history, as on «جدول اليوم»: «تم أخذها» or
/// «تم تخطيها» in their colours with who recorded it centred under it, or,
/// while nobody recorded it, its timing.
class DoseHistoryOutcome extends StatelessWidget {
  const DoseHistoryOutcome({
    super.key,
    required this.occurrence,
    required this.status,
    this.circleId,
  });

  final DoseOccurrence occurrence;

  /// Its pill as «جدول اليوم» says it; null while nobody recorded it.
  final DoseRowStatus? status;

  /// Needed to show who recorded it; null leaves the pill alone.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    if ((occurrence.record, status) case (
      final DoseRecord record,
      final DoseRowStatus pill,
    )) {
      final String? name = record.recordedByName;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StatusBadge(text: pill.label, tone: pill.tone),
          if ((circleId, name) case (final String circle, final String who))
            RecorderLine(
              name: who,
              photoPath: personPhotoPath(circle, record.recordedByAccountId),
              avatarCode: record.recordedByAvatarCode,
              large: true,
            ),
        ],
      );
    }
    return DoseTimingBadge(
      state: occurrence.timingState,
      scheduledOn: occurrence.scheduledOn,
    );
  }
}

/// Where a dose stands against its time: upcoming, due, late, or not
/// recorded. A missed dose of today or yesterday still says «غير مسجلة»,
/// because it is not proof the dose was skipped.
class DoseTimingBadge extends StatelessWidget {
  const DoseTimingBadge({
    super.key,
    required this.state,
    required this.scheduledOn,
  });

  final DoseTimingState? state;
  final DateTime scheduledOn;

  @override
  Widget build(BuildContext context) {
    final DoseTimingState? state = this.state;
    if (state == null) return const SizedBox.shrink();
    final DateTime yesterday = DateUtils.dateOnly(
      PatientClockScope.of(context).today(),
    ).subtract(const Duration(days: 1));
    final bool recentMissed =
        state == DoseTimingState.missed &&
        !DateUtils.dateOnly(scheduledOn).isBefore(yesterday);
    return StatusBadge(
      text: context.tr(
        recentMissed
            ? 'medications.timing.unrecorded'
            : 'medications.timing.${state.name}',
      ),
      tone: switch (state) {
        DoseTimingState.upcoming => StatusTone.info,
        DoseTimingState.due || DoseTimingState.late => StatusTone.attention,
        DoseTimingState.missed =>
          recentMissed ? StatusTone.attention : StatusTone.danger,
      },
    );
  }
}

/// Where a dose's answers are drawn, which decides how they are laid out:
/// the task-button grid of «اليوم» and «يحتاج انتباهك», or the plain row a
/// medicine's own history uses.
enum DoseControlsLayout { regular, today, attention }
