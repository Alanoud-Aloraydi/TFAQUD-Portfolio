import 'dart:math' as math;
import 'dart:ui';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// The geometry of a month chart, shared by what draws it and what answers
/// a tap, so the two can never disagree about where a bar is. Days run from
/// the right edge, as an Arabic page reads.
class ChartScale {
  ChartScale({required this.size, required this.days, required this.topValue});

  factory ChartScale.of(
    Size size,
    DateTime month,
    List<MeasurementReading> readings,
    int? targetHigh,
  ) {
    final List<int> values = <int>[
      for (final MeasurementReading reading in readings) ...<int>[
        if (reading.valueOne != null) reading.valueOne!,
        if (reading.valueTwo != null) reading.valueTwo!,
      ],
    ];
    final int highest = math.max(
      targetHigh ?? 0,
      values.fold<int>(0, math.max),
    );
    return ChartScale(
      size: size,
      days: DateTime(month.year, month.month + 1, 0).day,
      topValue: math.max(minTop, highest + headroom).toDouble(),
    );
  }

  static const double labelWidth = 29;
  static const double chartLeft = 4;
  static const double chartTop = 16;
  static const double bottomPad = 24;
  static const int minTop = 180;
  static const int headroom = 20;

  final Size size;
  final int days;
  final double topValue;

  double get chartBottom => size.height - bottomPad;
  double get slot => (size.width - labelWidth - chartLeft) / days;

  double y(num value) =>
      chartBottom - (value / topValue) * (chartBottom - chartTop);

  double x(int day) => size.width - labelWidth - (day - .5) * slot;

  /// The width of one bar when [count] readings share a day.
  double barWidth(int count) => math.min(8, math.max(5, slot / count - 1));

  /// The distance between the centres of bars that share a day.
  double barStep(int count) =>
      math.min(barWidth(count) + 1, math.max(3, slot / count));

  /// The centre of the [index]th of [count] bars on [day].
  double center(int day, int index, int count) =>
      x(day) + (index - (count - 1) / 2) * barStep(count);
}

/// The readings of [month] grouped by the day they fall on where the patient
/// lives, never the phone's zone.
Map<int, List<MeasurementReading>> readingsByDay(
  List<MeasurementReading> readings,
  DateTime month,
  PatientClock clock,
) {
  final Map<int, List<MeasurementReading>> byDay =
      <int, List<MeasurementReading>>{};
  for (final MeasurementReading reading in readings) {
    final DateTime? moment = reading.measuredAt;
    if (moment == null) continue;
    final DateTime at = clock.wallTime(moment);
    if (at.year != month.year || at.month != month.month) continue;
    byDay.putIfAbsent(at.day, () => <MeasurementReading>[]).add(reading);
  }
  return byDay;
}
