import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// [codes] on one line: «بعد الوجبة، بعد جهد».
String conditionsText(BuildContext context, List<String> codes) =>
    codes.map((code) => context.tr('measurements.condition.$code')).join('، ');

/// A reading's conditions on one line, «أخرى» in the reader's words when
/// they wrote some: «بعد جهد، بعد القهوة».
String readingConditionsText(
  BuildContext context,
  MeasurementReading reading,
) => <String>[
  for (final String code in reading.conditions)
    if (code == 'other' && reading.otherCondition != null)
      reading.otherCondition!
    else
      context.tr('measurements.condition.$code'),
].join('، ');
