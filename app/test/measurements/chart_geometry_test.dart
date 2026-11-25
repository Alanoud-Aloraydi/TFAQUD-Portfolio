import 'dart:ui';

import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

/// [year]'s Gregorian [month], as the chart reads it.
CalendarMonth _month(int year, int month) =>
    CalendarMonth.of(DateTime(year, month), DateCalendar.gregorian);

MeasurementReading _glucose(
  DateTime at, {
  int? low,
  int? high,
  String state = 'after_meal',
  DateTime? recordedAt,
}) => MeasurementReading(
  id: '$at',
  kind: MeasurementKind.glucose,
  outcome: 'read',
  recordedAt: recordedAt ?? at,
  measuredAt: at,
  valueOne: 100,
  range: low == null
      ? null
      : ReadingRange(
          profile: 'general',
          state: state,
          normal: NormalBand(
            level: MeasurementLevel.normal,
            glucoseLow: low,
            glucoseHigh: high,
          ),
        ),
);

MeasurementReading _pressure(DateTime at) => MeasurementReading(
  id: '$at',
  kind: MeasurementKind.bp,
  outcome: 'read',
  recordedAt: at,
  measuredAt: at,
  valueOne: 118,
  valueTwo: 76,
  range: const ReadingRange(
    profile: 'general',
    normal: NormalBand(
      level: MeasurementLevel.normal,
      systolicLow: 90,
      systolicHigh: 120,
      diastolicLow: 60,
      diastolicHigh: 80,
    ),
  ),
);

void main() {
  group('readingsByDay', () {
    test('uses the patient day, not the UTC day', () {
      // 22:30 UTC on 30 Nov is 01:30 on 1 Dec in Riyadh.
      final MeasurementReading late = _glucose(
        DateTime.utc(2026, 11, 30, 22, 30),
      );

      final Map<int, List<MeasurementReading>> december = readingsByDay(
        <MeasurementReading>[late],
        _month(2026, 12),
        PatientClock('Asia/Riyadh'),
      );

      expect(december.keys, <int>[1]);
    });

    test('keeps a day in the order it was measured, not recorded', () {
      final DateTime morning = DateTime.utc(2026, 11, 5, 5);
      final DateTime evening = DateTime.utc(2026, 11, 5, 15);
      // The server sends the last recorded first: the morning reading was
      // recorded after the evening one.
      final List<MeasurementReading> sent = <MeasurementReading>[
        _glucose(morning, recordedAt: DateTime.utc(2026, 11, 5, 18)),
        _glucose(evening),
      ];

      final List<MeasurementReading> day = readingsByDay(
        sent,
        _month(2026, 11),
        PatientClock('Asia/Riyadh'),
      )[5]!;

      expect(day.map((reading) => reading.measuredAt), <DateTime>[
        morning,
        evening,
      ]);
    });
  });

  group('ChartScale', () {
    test('puts day 1 at the right edge and the top value at the top', () {
      final ChartScale scale = ChartScale.of(
        const Size(400, 176),
        _month(2026, 11),
        const <MeasurementReading>[],
        null,
      );

      expect(scale.x(1), greaterThan(scale.x(30)));
      expect(scale.y(scale.topValue), ChartScale.chartTop);
      expect(scale.days, 30);
    });

    test('inside a day the earlier reading is to the right as well', () {
      final ChartScale scale = ChartScale.of(
        const Size(400, 176),
        _month(2026, 11),
        const <MeasurementReading>[],
        null,
      );

      // Morning, noon, evening of day 5, then day 6: always further left.
      final List<double> xs = <double>[
        for (int index = 0; index < 3; index++) scale.center(5, index, 3),
        scale.center(6, 0, 1),
      ];

      for (int i = 1; i < xs.length; i++) {
        expect(xs[i], lessThan(xs[i - 1]));
      }
    });

    test('the axis holds the readings, not everything down to zero', () {
      final ChartScale scale = ChartScale.of(
        const Size(400, 176),
        _month(2026, 11),
        <MeasurementReading>[_glucose(DateTime.utc(2026, 11, 5, 9))],
        140,
        targetLow: 70,
      );

      expect(scale.bottomValue, greaterThan(0));
      expect(scale.bottomValue, lessThanOrEqualTo(60));
      expect(scale.topValue, greaterThanOrEqualTo(200));
      expect(scale.y(scale.bottomValue), scale.chartBottom);
      // Two readings 20 apart are 20 apart on the chart.
      expect(scale.y(100) - scale.y(120), greaterThan(8));
    });

    test('labels four round lines', () {
      final ChartScale scale = ChartScale.of(
        const Size(400, 176),
        _month(2026, 11),
        <MeasurementReading>[_glucose(DateTime.utc(2026, 11, 5, 9))],
        140,
        targetLow: 70,
      );

      expect(scale.ticks, hasLength(4));
      expect(scale.ticks.first, lessThan(scale.ticks.last));
      for (final int tick in scale.ticks) {
        expect(tick % 5, 0);
      }
    });
  });

  group('ChartTarget', () {
    final DateTime at = DateTime.utc(2026, 11, 5, 9);

    test('is the normal band the readings share', () {
      final ChartTarget target = ChartTarget.of(
        kind: MeasurementKind.glucose,
        readings: <MeasurementReading>[
          _glucose(at, low: 70, high: 140),
          _glucose(at.add(const Duration(days: 1)), low: 70, high: 140),
        ],
      );

      expect(target.bands, const <ChartBand>[
        ChartBand(70, 140, 'measurements.chart_legend_glucose_target'),
      ]);
      expect((target.low, target.high), (70, 140));
    });

    test('fasting and after a meal: both bands, fasting inside', () {
      final ChartTarget target = ChartTarget.of(
        kind: MeasurementKind.glucose,
        readings: <MeasurementReading>[
          _glucose(at, low: 80, high: 130, state: 'fasting'),
          _glucose(at, low: 70, high: 180),
        ],
      );

      expect(target.bands, const <ChartBand>[
        ChartBand(70, 180, 'measurements.chart_legend_after_meal'),
        ChartBand(80, 130, 'measurements.chart_legend_fasting', inner: true),
      ]);
      expect((target.low, target.high), (70, 180));
    });

    test('uses the latest range when the medical file changed', () {
      final ChartTarget target = ChartTarget.of(
        kind: MeasurementKind.glucose,
        readings: <MeasurementReading>[
          _glucose(at.add(const Duration(days: 1)), low: 70, high: 180),
          _glucose(at, low: 70, high: 140),
        ],
      );

      expect(target.high, 180);
      expect(target.bands, hasLength(1));
    });

    test('blood pressure: the zone of each number, under one name', () {
      final ChartTarget target = ChartTarget.of(
        kind: MeasurementKind.bp,
        readings: <MeasurementReading>[_pressure(at)],
      );

      expect(target.bands, const <ChartBand>[
        ChartBand(90, 120, 'measurements.chart_legend_bp_target'),
        ChartBand(60, 80, 'measurements.chart_legend_bp_target'),
      ]);
    });

    test('nothing to draw without a judged reading', () {
      final ChartTarget target = ChartTarget.of(
        kind: MeasurementKind.glucose,
        readings: <MeasurementReading>[_glucose(at)],
      );

      expect(target.isSet, isFalse);
      expect(target.low, isNull);
    });
  });
}
