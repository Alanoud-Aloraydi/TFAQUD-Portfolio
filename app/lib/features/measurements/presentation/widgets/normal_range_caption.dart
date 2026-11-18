import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/normal_band_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Which range it is, in words: «صائم أو قبل الوجبة، مصاب بالسكري».
String normalRangeCaption(
  BuildContext context,
  MeasurementKind kind,
  String profile,
  String? state,
) {
  final String who = context.tr(
    'measurements.range_profile.${profile == 'general' ? '${kind.name}_general' : profile}',
  );
  if (kind == MeasurementKind.bp) return who;
  return '${context.tr('measurements.range_state.$state')}، $who';
}

/// «المعدل الطبيعي: 70–100 ملغ/دل، صائم أو قبل الوجبة، غير مصاب بالسكري»:
/// the range [reading] was judged by, in one line.
String readingRangeText(BuildContext context, MeasurementReading reading) {
  final ReadingRange range = reading.range!;
  final String unit = context.tr(
    reading.kind == MeasurementKind.bp
        ? 'measurements.bp_unit'
        : 'measurements.glucose_unit',
  );
  return '${context.tr('measurements.normal_range')}: '
      '${normalBandText(context, reading.kind, range.normal)} $unit، '
      '${normalRangeCaption(context, reading.kind, range.profile, range.state)}';
}
