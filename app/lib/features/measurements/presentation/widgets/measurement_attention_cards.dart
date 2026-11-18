import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/missed_measurement_card.dart';
import 'package:app/features/measurements/presentation/widgets/outside_reading_card.dart';
import 'package:flutter/material.dart';

/// The cards of the attention box, drawn as readings are in «السجل»:
/// «سجّل» and «تخطي» for a missed task (only «تخطي» once the next task of
/// its kind is due at [now], a wall time), «تابعتها» for a reading outside
/// its normal range, with its value, level and range.
List<Widget> measurementAttentionCards(
  BuildContext context,
  List<MeasurementOccurrence> missed,
  List<MeasurementReading> outside, {
  required DateTime now,
  String? circleId,
}) => <Widget>[
  for (final MeasurementOccurrence task in missed)
    MissedMeasurementCard(task: task, now: now, circleId: circleId),
  for (final MeasurementReading reading in outside)
    OutsideReadingCard(reading: reading),
];
