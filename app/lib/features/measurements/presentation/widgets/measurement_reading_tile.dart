import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/reading_extras.dart';
import 'package:app/features/measurements/presentation/widgets/reading_status_pill.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// One glucose or blood pressure reading, the same everywhere it is listed,
/// in the one card of «السجل» ([RecordItemCard]): the kind and when, the
/// value with its unit at the end, where it stands against the target,
/// then the details. A reading outside its target is tinted yellow. At
/// large text sizes the value drops under the title instead of squeezing
/// it.
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
      attention: reading.outsideTarget == true,
      leading: Icon(
        reading.kind == MeasurementKind.glucose
            ? CupertinoIcons.drop
            : CupertinoIcons.heart,
      ),
      title: ReadingTitles(reading: reading),
      status: _skipped
          ? StatusBadge(
              text: context.tr('measurements.skipped'),
              tone: StatusTone.muted,
            )
          : ReadingValue(reading: reading),
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
