import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «8:00 ص» for today, «الأحد 8:00 ص» for a day before it.
String simplifiedReadingWhen(
  BuildContext context,
  MeasurementReading reading,
  DateTime now,
) {
  final DateTime at = reading.measuredAt ?? reading.recordedAt;
  final String clock = wallTimeText(at);
  if (DateUtils.isSameDay(at, now)) return clock;
  return '${context.tr('common.weekdays.${at.weekday}')} $clock';
}
