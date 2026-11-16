import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:flutter/material.dart';

/// What became of a recorded dose, in the top corner of its card as on
/// «جدول اليوم»: «تم أخذها» or «تم تخطيها» in their colours, and under it
/// who recorded it, their photo before their name.
class DoseHistoryOutcome extends StatelessWidget {
  const DoseHistoryOutcome({
    super.key,
    required this.record,
    required this.status,
    this.circleId,
  });

  final DoseRecord record;
  final DoseRowStatus status;

  /// Needed to show who recorded it; null leaves the badge alone.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final String? name = record.recordedByName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        StatusBadge(text: status.label, tone: status.tone),
        if ((circleId, name) case (final String circle, final String who))
          RecorderLine(
            name: who,
            photoPath: personPhotoPath(circle, record.recordedByAccountId),
            avatarCode: record.recordedByAvatarCode,
          ),
      ],
    );
  }
}
