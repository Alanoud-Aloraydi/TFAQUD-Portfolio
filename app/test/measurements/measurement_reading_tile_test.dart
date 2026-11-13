import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

MeasurementReading _reading({
  MeasurementKind kind = MeasurementKind.glucose,
  String outcome = 'read',
  bool? outsideTarget,
  int valueOne = 110,
  int? valueTwo,
  MeasurementLevel? level,
  ReadingRange? range,
}) => MeasurementReading(
  id: 'reading-1',
  kind: kind,
  outcome: outcome,
  recordedAt: noonInRiyadh,
  measuredAt: outcome == 'read' ? noonInRiyadh : null,
  scheduledOn: DateTime(2026, 11, 9),
  valueOne: outcome == 'read' ? valueOne : null,
  valueTwo: valueTwo,
  outsideTarget: outsideTarget,
  level: level,
  range: range,
);

Future<void> _pump(
  WidgetTester tester,
  MeasurementReading reading, {
  double textScale = 1,
}) => pumpArabic(
  tester,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SingleChildScrollView(
          child: MeasurementReadingTile(reading: reading, circleId: 'circle-1'),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('MeasurementReadingTile', () {
    testWidgets('shows glucose with its unit and the time in Riyadh', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _reading(outsideTarget: false));

      expect(find.text('110'), findsOneWidget);
      expect(find.text('measurements.glucose_unit'.tr()), findsOneWidget);
      expect(find.textContaining('12:00'), findsOneWidget);
      expect(find.text('measurements.in_target'.tr()), findsOneWidget);
    });

    testWidgets('shows blood pressure as one left-to-right number', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _reading(
          kind: MeasurementKind.bp,
          valueOne: 150,
          valueTwo: 95,
          outsideTarget: true,
        ),
      );

      final Text value = tester.widget<Text>(find.text('150/95'));
      expect(value.textDirection, TextDirection.ltr);
      expect(find.text('measurements.bp_unit'.tr()), findsOneWidget);
      expect(find.text('measurements.outside_target'.tr()), findsOneWidget);
    });

    testWidgets('says the level and the normal range it was judged by', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _reading(
          valueOne: 151,
          outsideTarget: true,
          level: MeasurementLevel.high,
          range: const ReadingRange(
            profile: 'general',
            state: 'fasting',
            normal: NormalBand(
              level: MeasurementLevel.normal,
              glucoseLow: 70,
              glucoseHigh: 100,
            ),
          ),
        ),
      );

      expect(find.text('measurements.level.high'.tr()), findsOneWidget);
      expect(find.textContaining('70–100'), findsOneWidget);
      expect(
        find.textContaining('measurements.range_state.fasting'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('says a reading has no target when it has none', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _reading());

      expect(find.text('measurements.without_target'.tr()), findsOneWidget);
    });

    testWidgets('a skipped reading shows no value', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _reading(outcome: 'skipped'));

      expect(find.text('measurements.skipped'.tr()), findsOneWidget);
      expect(find.text('measurements.glucose_unit'.tr()), findsNothing);
    });

    testWidgets('does not overflow at a very large text size', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _reading(outsideTarget: true), textScale: 2.5);

      expect(tester.takeException(), isNull);
      expect(find.text('110'), findsOneWidget);
    });
  });
}
