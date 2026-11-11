import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/home/data/record_pdf_model.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/domain/record_export_options.dart';
import 'package:app/features/home/presentation/export/record_document.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

MeasurementReading _reading(
  MeasurementKind kind,
  DateTime at,
  int one, {
  int? two,
  bool outside = false,
}) => MeasurementReading(
  id: '$kind$at',
  kind: kind,
  outcome: 'read',
  recordedAt: at,
  measuredAt: at,
  valueOne: one,
  valueTwo: two,
  outsideTarget: outside,
  glucoseLow: 70,
  glucoseHigh: 140,
  systolicLimit: 140,
  diastolicLimit: 90,
);

Future<RecordPdfDocument> _build(
  WidgetTester tester,
  List<MeasurementReading> readings, {
  RecordExportOptions options = const RecordExportOptions(),
}) async {
  late RecordPdfDocument document;
  final PatientClock clock = PatientClock(
    'Asia/Riyadh',
    clock: () => noonInRiyadh,
  );
  await pumpArabic(
    tester,
    home: Builder(
      builder: (context) {
        document = buildRecordDocument(
          context,
          RecordExportData(
            options: options,
            period: ExportPeriod(DateTime(2026, 11), DateTime(2026, 11, 9)),
            clock: clock,
            plans: const [],
            readings: readings,
          ),
        );
        return const SizedBox();
      },
    ),
  );
  return document;
}

void main() {
  setUpAll(initTestLocalization);

  testWidgets('puts the time zone in the header', (tester) async {
    final RecordPdfDocument document = await _build(tester, const []);

    final RecordPdfRow zone = document.header.singleWhere(
      (row) => row.label == 'record_export.time_zone'.tr(),
    );
    expect(zone.value, 'Asia/Riyadh');
  });

  testWidgets('orders the sections: summary, measurements, medications, '
      'appointments', (tester) async {
    final RecordPdfDocument document = await _build(tester, const []);

    expect(document.sections.map((s) => s.title), <String>[
      'record_export.summary'.tr(),
      'record_export.measurements'.tr(),
      'record_export.medications'.tr(),
      'record_export.appointments'.tr(),
    ]);
  });

  testWidgets('writes readings as a table per kind in the patient zone', (
    tester,
  ) async {
    // 22:30 UTC on 8 Nov is 01:30 on 9 Nov in Riyadh.
    final DateTime late = DateTime.utc(2026, 11, 8, 22, 30);
    final RecordPdfDocument document = await _build(
      tester,
      <MeasurementReading>[
        _reading(MeasurementKind.glucose, late, 180, outside: true),
        _reading(MeasurementKind.bp, late, 120, two: 80),
      ],
    );

    final RecordPdfSection section = document.sections.singleWhere(
      (s) => s.title == 'record_export.measurements'.tr(),
    );
    expect(section.tables, hasLength(2));
    final List<RecordPdfCell> row = section.tables.first.rows.single;
    expect(row[0].text, contains('9'));
    expect(row[1].text, contains('1:30'));
    expect(row[2].text, '180');
    expect(row[2].warn, isTrue);
  });

  testWidgets('leaves out the sections that were not chosen', (tester) async {
    final RecordPdfDocument document = await _build(
      tester,
      const [],
      options: const RecordExportOptions(
        measurements: false,
        appointments: false,
      ),
    );

    expect(document.sections.map((s) => s.title), <String>[
      'record_export.summary'.tr(),
      'record_export.medications'.tr(),
    ]);
  });
}
