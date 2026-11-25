import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// A reading's number and its unit, stacked; its level badge says whether
/// it is in range, so the number keeps the text colour. The number is set left to right
/// on its own so «120/80» never reverses on an Arabic page; the unit sits
/// under it so the two never mix directions in one line.
class ReadingValue extends StatelessWidget {
  const ReadingValue({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool bp = reading.kind == MeasurementKind.bp;
    return Semantics(
      label: spoken(
        '${reading.spokenValue(context.tr('measurements.over'))} '
        '${context.tr(bp ? 'measurements.bp_unit' : 'measurements.glucose_unit')}',
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            reading.valueText,
            textDirection: TextDirection.ltr,
            style: text.headlineSmall?.copyWith(
              color: AppSemanticColors.textPrimary,
            ),
          ),
          Text(
            context.tr(
              bp ? 'measurements.bp_unit' : 'measurements.glucose_unit',
            ),
            style: text.labelSmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

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
