import 'dart:ui';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

MeasurementReading _glucose(DateTime at, {int? low, int? high}) =>
    MeasurementReading(
      id: '$at',
      kind: MeasurementKind.glucose,
      outcome: 'read',
      recordedAt: at,
      measuredAt: at,
      valueOne: 100,
      range: low == null
          ? null
          : ReadingRange(
              profile: 'general',
              state: 'after_meal',
              normal: NormalBand(
                level: MeasurementLevel.normal,
                glucoseLow: low,
                glucoseHigh: high,
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
        DateTime(2026, 12),
        PatientClock('Asia/Riyadh'),
      );

      expect(december.keys, <int>[1]);
    });
  });

  group('ChartScale', () {
    test('puts day 1 at the right edge and the top value at the top', () {
      final ChartScale scale = ChartScale.of(
        const Size(400, 176),
        DateTime(2026, 11),
        const <MeasurementReading>[],
        null,
      );

      expect(scale.x(1), greaterThan(scale.x(30)));
      expect(scale.y(scale.topValue), ChartScale.chartTop);
      expect(scale.days, 30);
    });
  });

  group('ChartTarget', () {
    test('is the normal band every reading shares', () {
      final DateTime at = DateTime.utc(2026, 11, 5, 9);
      final ChartTarget target = ChartTarget.of(
        kind: MeasurementKind.glucose,
        readings: <MeasurementReading>[
          _glucose(at, low: 70, high: 140),
          _glucose(at.add(const Duration(days: 1)), low: 70, high: 140),
        ],
      );

      expect((target.low, target.high), (70, 140));
    });

    test('is empty when readings were judged by different ranges', () {
      final DateTime at = DateTime.utc(2026, 11, 5, 9);
      final ChartTarget target = ChartTarget.of(
        kind: MeasurementKind.glucose,
        readings: <MeasurementReading>[
          _glucose(at, low: 70, high: 140),
          _glucose(at, low: 80, high: 150),
        ],
      );

      expect(target.isSet, isFalse);
    });
  });
}
