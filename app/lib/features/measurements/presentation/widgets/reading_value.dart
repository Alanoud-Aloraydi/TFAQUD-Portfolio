import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/measurements/domain/measurement.dart';
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
      label:
          '${reading.valueText} '
          '${context.tr(bp ? 'measurements.bp_unit' : 'measurements.glucose_unit')}',
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
