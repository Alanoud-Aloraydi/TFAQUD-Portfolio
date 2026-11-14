import 'dart:math' as math;
import 'dart:ui';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// The geometry of a month chart, shared by what draws it and what answers
/// a tap, so the two can never disagree about where a bar is. Days run from
/// the right edge, as an Arabic page reads.
class ChartScale {
  ChartScale({
    required this.size,
    required this.days,
    required this.topValue,
    this.bottomValue = 0,
  });

  factory ChartScale.of(
    Size size,
    DateTime month,
    List<MeasurementReading> readings,
    int? targetHigh, {
    int? targetLow,
    MeasurementKind kind = MeasurementKind.glucose,
  }) {
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
    final int lowest = values.isEmpty
        ? 0
        : math.min(targetLow ?? 999, values.reduce(math.min));
    // A reading of 150 next to one of 130 has to look different, so the
    // axis holds the range of the readings, not everything down to zero.
    final (int floor, int ceiling) = switch (kind) {
      MeasurementKind.glucose => (60, 200),
      MeasurementKind.bp => (50, 160),
    };
    final double bottom =
        (math.min(floor, lowest - 10) / 10).floorToDouble() * 10;
    final double top =
        (math.max(ceiling, highest + 15) / 10).ceilToDouble() * 10;
    return ChartScale(
      size: size,
      days: DateTime(month.year, month.month + 1, 0).day,
      topValue: top,
      bottomValue: values.isEmpty && targetHigh == null ? 0 : bottom,
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

  /// Where the axis starts. Readings live well above zero, so the chart
  /// does too.
  final double bottomValue;

  double get chartBottom => size.height - bottomPad;
  double get slot => (size.width - labelWidth - chartLeft) / days;

  double y(num value) =>
      chartBottom -
      ((value.clamp(bottomValue, topValue) - bottomValue) /
              (topValue - bottomValue)) *
          (chartBottom - chartTop);

  /// The four lines the chart draws and labels, in round numbers.
  List<int> get ticks {
    final double step = (topValue - bottomValue) / 3;
    return <int>[
      for (int index = 0; index < 4; index++)
        ((bottomValue + step * index) / 5).round() * 5,
    ];
  }

  double x(int day) => size.width - labelWidth - (day - .5) * slot;

  /// The width of one bar when [count] readings share a day.
  double barWidth(int count) => math.min(9, math.max(6, slot / count - 1));

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
