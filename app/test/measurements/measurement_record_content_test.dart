import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_state.dart';
import 'package:app/features/measurements/presentation/measurement_record_filter.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_content.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// [year]'s Gregorian [month], as the chart reads it.
CalendarMonth _month(int year, int month) =>
    CalendarMonth.of(DateTime(year, month), DateCalendar.gregorian);

MeasurementReading _reading(MeasurementKind kind, {String outcome = 'read'}) =>
    MeasurementReading(
      id: '${kind.name}-$outcome',
      kind: kind,
      outcome: outcome,
      recordedAt: noonInRiyadh,
      measuredAt: outcome == 'read' ? noonInRiyadh : null,
      scheduledOn: DateTime(2026, 11, 9),
      valueOne: outcome == 'read' ? 128 : null,
      valueTwo: outcome == 'read' && kind == MeasurementKind.bp ? 80 : null,
    );

Future<void> _pump(
  WidgetTester tester,
  List<MeasurementReading> readings, {
  VoidCallback? onAdd,
}) => pumpArabic(
  tester,
  home: Scaffold(
    body: ListView(
      children: measurementRecordContent(
        MeasurementReadingsState(
          status: MeasurementLoadStatus.ready,
          readings: readings,
        ),
        circleId: 'circle-1',
        month: _month(2026, 11),
        filter: MeasurementRecordFilter.all,
        onRetry: () {},
        onAddReading: onAdd,
      ),
    ),
  ),
);

Finder _chart(MeasurementKind kind) => find.byWidgetPredicate(
  (Widget w) => w is MeasurementChartCard && w.kind == kind,
);

void main() {
  setUpAll(initTestLocalization);

  group('«السجل» readings', () {
    testWidgets('a month with none shows the note and its add, no chart', (
      WidgetTester tester,
    ) async {
      int added = 0;
      await _pump(tester, const <MeasurementReading>[], onAdd: () => added++);

      expect(find.text('measurements.no_records'.tr()), findsOneWidget);
      expect(find.byType(MeasurementChartCard), findsNothing);
      await tester.tap(find.text('measurements.record_reading'.tr()));
      expect(added, 1);
    });

    testWidgets('without a way to record, the note has no add', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const <MeasurementReading>[]);

      expect(find.text('measurements.no_records'.tr()), findsOneWidget);
      expect(find.text('measurements.record_reading'.tr()), findsNothing);
    });

    testWidgets('a first sugar reading draws only the sugar chart', (
      WidgetTester tester,
    ) async {
      await _pump(tester, <MeasurementReading>[
        _reading(MeasurementKind.glucose),
      ]);

      expect(_chart(MeasurementKind.glucose), findsOneWidget);
      expect(_chart(MeasurementKind.bp), findsNothing);
      expect(find.text('measurements.no_records'.tr()), findsNothing);
    });

    testWidgets('a skipped reading alone draws no chart', (
      WidgetTester tester,
    ) async {
      await _pump(tester, <MeasurementReading>[
        _reading(MeasurementKind.bp, outcome: 'skipped'),
      ]);

      expect(find.byType(MeasurementChartCard), findsNothing);
      expect(find.text('measurements.no_records'.tr()), findsNothing);
    });
  });
}
