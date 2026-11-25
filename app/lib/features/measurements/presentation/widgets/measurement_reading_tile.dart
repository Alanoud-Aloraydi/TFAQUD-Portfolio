import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/reading_number_field.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// One reading in the card of «السجل» ([RecordItemCard]): the kind and
/// when, the value at the end with who recorded it centred under it (as
/// «جدول اليوم» puts the person under its pill), its level in the range,
/// then the details.
/// At large text sizes the value drops under the title instead of
/// squeezing it.
class MeasurementReadingTile extends StatelessWidget {
  const MeasurementReadingTile({
    super.key,
    required this.reading,
    required this.circleId,
  });

  final MeasurementReading reading;
  final String circleId;

  bool get _skipped => reading.outcome == 'skipped';

  @override
  Widget build(BuildContext context) {
    return RecordItemCard(
      leading: Icon(
        reading.kind == MeasurementKind.glucose
            ? CupertinoIcons.drop
            : CupertinoIcons.heart,
      ),
      title: ReadingTitles(reading: reading),
      status: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_skipped)
            StatusBadge(
              text: context.tr('measurements.skipped'),
              tone: StatusTone.muted,
            )
          else
            ReadingValue(reading: reading),
          if (reading.recordedByName case final String name)
            RecorderLine(
              name: name,
              photoPath: personPhotoPath(circleId, reading.recordedByAccountId),
              avatarCode: reading.recordedByAvatarCode,
              large: true,
            ),
        ],
      ),
      body: <Widget>[
        if (!_skipped)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ReadingStatusPill(reading: reading),
          ),
        ReadingExtras(reading: reading, circleId: circleId),
      ],
    );
  }
}
