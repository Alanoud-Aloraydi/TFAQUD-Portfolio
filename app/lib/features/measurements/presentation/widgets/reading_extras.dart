import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The lines under a reading: the normal range it was judged by, its
/// conditions, the reason it was skipped and the note. Each one shows only
/// when it has something. Who recorded it is in the card's top corner,
/// under the value, as «جدول اليوم» shows it.
class ReadingExtras extends StatelessWidget {
  const ReadingExtras({
    super.key,
    required this.reading,
    required this.circleId,
  });

  final MeasurementReading reading;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.tokens.textSecondary);
    final bool skipped = reading.outcome == 'skipped';
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!skipped && reading.range != null)
            Text(readingRangeText(context, reading), style: style),
          if (!skipped && reading.conditions.isNotEmpty)
            Text(readingConditionsText(context, reading), style: style),
          if (skipped && reading.skipReasonCode != null)
            Text(
              context.tr(
                'measurements.skip_reason_line',
                args: <String>[measurementSkipReasonText(context, reading)],
              ),
              style: style,
            ),
          if (reading.note != null) Text(reading.note!, style: style),
        ],
      ),
    );
  }
}
