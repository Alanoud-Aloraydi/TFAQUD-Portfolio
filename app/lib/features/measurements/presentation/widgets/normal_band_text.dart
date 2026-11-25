import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// [band]'s values as people read them: «70–100», «أقل من 70», «126
/// فأكثر»; blood pressure as systolic over diastolic, «90–120 / 60–80».
/// Numbers are kept left to right inside Arabic text, so «70–100» is not
/// shown as «100–70».
String normalBandText(
  BuildContext context,
  MeasurementKind kind,
  NormalBand band,
) {
  if (kind == MeasurementKind.glucose) return _glucose(context, band);
  if (band.level == MeasurementLevel.low) {
    return context.tr(
      'measurements.range_below',
      args: [_ltr('${band.systolicHigh! + 1}/${band.diastolicHigh! + 1}')],
    );
  }
  if (band.level == MeasurementLevel.high) {
    return context.tr(
      'measurements.range_from',
      args: [_ltr('${band.systolicLow}/${band.diastolicLow}')],
    );
  }
  return _ltr(normalBandNumbers(kind, band));
}

/// The numbers of a closed band with no marks around them, for a cell
/// that is set left to right already (the PDF): «70–100», «90–120 /
/// 60–80».
String normalBandNumbers(MeasurementKind kind, NormalBand band) =>
    kind == MeasurementKind.glucose
    ? '${band.glucoseLow}–${band.glucoseHigh}'
    : '${band.systolicLow}–${band.systolicHigh} / '
          '${band.diastolicLow}–${band.diastolicHigh}';

String _glucose(BuildContext context, NormalBand band) {
  final int? low = band.glucoseLow;
  final int? high = band.glucoseHigh;
  if (low == null) {
    return context.tr('measurements.range_below', args: ['${high! + 1}']);
  }
  if (high == null) {
    return context.tr('measurements.range_from', args: ['$low']);
  }
  return _ltr(normalBandNumbers(MeasurementKind.glucose, band));
}

/// [value] isolated left to right (U+2066 … U+2069).
String _ltr(String value) => '\u2066$value\u2069';
