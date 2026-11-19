import 'dart:ui';

import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_hit.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';
import 'package:flutter_test/flutter_test.dart';

/// [year]'s Gregorian [month], as the chart reads it.
CalendarMonth _month(int year, int month) =>
    CalendarMonth.of(DateTime(year, month), DateCalendar.gregorian);

/// A chart whose days share 300 points at zoom 1: 10 a day in November.
ChartScale _scale([ChartZoom view = ChartZoom.none]) => ChartScale.of(
  const Size(333, 176),
  _month(2026, 11),
  const <MeasurementReading>[],
  null,
  view: view,
);

MeasurementReading _glucose(int day) => MeasurementReading(
  id: 'r-$day',
  kind: MeasurementKind.glucose,
  outcome: 'read',
  recordedAt: DateTime(2026, 11, day, 8),
  measuredAt: DateTime(2026, 11, day, 8),
  valueOne: 100,
);

void main() {
  group('ChartZoom', () {
    test('a pinch keeps the day under the fingers under them', () {
      final double before = _scale().x(10);
      final double fromRight = _scale().right - before;

      final ChartZoom view = ChartZoom.none.moved(
        from: fromRight,
        at: fromRight,
        to: 3,
        width: ChartScale.plotWidth(333),
      );

      expect(view.zoom, 3);
      expect(_scale(view).x(10), closeTo(before, .001));
    });

    test('zooming in spreads the days apart', () {
      final ChartScale near = _scale();
      final ChartScale far = _scale(const ChartZoom(zoom: 3));

      expect(far.x(1) - far.x(2), closeTo(3 * (near.x(1) - near.x(2)), .001));
      expect(far.labelDays.length, greaterThan(near.labelDays.length));
    });

    test('never past day 1, the month end, or six times', () {
      final double width = ChartScale.plotWidth(333);

      expect(
        ChartZoom.none.moved(from: 0, at: 200, to: 1, width: width).shift,
        0,
      );
      expect(
        const ChartZoom(zoom: 2)
            .moved(from: 0, at: -1000, to: 2, width: width)
            .shift,
        width,
      );
      expect(
        ChartZoom.none.moved(from: 0, at: 0, to: 10, width: width).zoom,
        ChartZoom.most,
      );
    });
  });

  group('chartReadingAt', () {
    test('finds the reading under the finger', () {
      final ChartScale scale = _scale();
      final MeasurementReading reading = _glucose(10);

      expect(
        chartReadingAt(
          scale,
          <int, List<MeasurementReading>>{
            10: <MeasurementReading>[reading],
          },
          MeasurementKind.glucose,
          Offset(scale.x(10), scale.y(100)),
        ),
        reading,
      );
    });

    test('a reading scrolled out of view cannot be tapped', () {
      // Zoomed in on the first days, day 30 is far off to the left.
      final ChartScale scale = _scale(const ChartZoom(zoom: 6));
      final double x = scale.x(30);

      expect(x, lessThan(ChartScale.chartLeft));
      expect(
        chartReadingAt(
          scale,
          <int, List<MeasurementReading>>{
            30: <MeasurementReading>[_glucose(30)],
          },
          MeasurementKind.glucose,
          Offset(x, scale.y(100)),
        ),
        isNull,
      );
    });
  });
}
