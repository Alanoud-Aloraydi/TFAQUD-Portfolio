import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// How many [readings] a month has and how many of them are outside their
/// range, or that it has none.
String readingCountText(
  BuildContext context,
  List<MeasurementReading> readings,
) => readings.isEmpty
    ? context.tr('measurements.no_readings')
    : context.tr(
        'measurements.reading_count',
        args: <String>[
          '${readings.length}',
          '${readings.where((r) => r.outsideTarget == true).length}',
        ],
      );
