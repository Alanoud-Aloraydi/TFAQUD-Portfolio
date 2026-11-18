import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The kind of reading a month card is about, and its [latest] value.
class MeasurementChartCardHeader extends StatelessWidget {
  const MeasurementChartCardHeader({
    super.key,
    required this.kind,
    required this.latest,
  });

  final MeasurementKind kind;
  final MeasurementReading? latest;

  @override
  Widget build(BuildContext context) {
    final bool glucose = kind == MeasurementKind.glucose;
    return Row(
      children: <Widget>[
        Icon(glucose ? CupertinoIcons.drop : CupertinoIcons.heart),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.tr(glucose ? 'measurements.glucose' : 'measurements.bp'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (latest case final MeasurementReading reading)
          ReadingValue(reading: reading),
      ],
    );
  }
}
