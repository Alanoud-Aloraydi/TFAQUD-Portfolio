import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_timing_badge.dart';
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
