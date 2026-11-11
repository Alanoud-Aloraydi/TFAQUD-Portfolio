import 'package:app/features/home/domain/export_filename.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime today = DateTime(2026, 11, 9);
  final DateTime earliest = DateTime(2026, 1, 15);

  ExportPeriod of(ExportRange range, {ExportPeriod? custom}) =>
      ExportPeriod.of(range, today: today, earliest: earliest, custom: custom);

  group('ExportPeriod', () {
    test('the ready-made spans end today and include it', () {
      expect(of(ExportRange.last7).start, DateTime(2026, 11, 3));
      expect(of(ExportRange.last30).start, DateTime(2026, 10, 11));
      expect(of(ExportRange.last90).start, DateTime(2026, 8, 12));
      expect(of(ExportRange.last7).end, today);
    });

    test('the whole record starts at the earliest plan', () {
      expect(of(ExportRange.all).start, earliest);
    });

    test('a custom span is the one the person picked', () {
      final ExportPeriod picked = ExportPeriod(
        DateTime(2026, 3),
        DateTime(2026, 3, 10),
      );

      expect(of(ExportRange.custom, custom: picked), picked);
    });

    test('contains both ends and ignores the clock time', () {
      final ExportPeriod period = of(ExportRange.last7);

      expect(period.contains(DateTime(2026, 11, 3, 0, 1)), isTrue);
      expect(period.contains(DateTime(2026, 11, 9, 23, 59)), isTrue);
      expect(period.contains(DateTime(2026, 11, 2, 23, 59)), isFalse);
      expect(period.contains(DateTime(2026, 11, 10)), isFalse);
    });
  });

  group('exportFilename', () {
    test('keeps letters and digits and writes both ends of the period', () {
      expect(
        exportFilename('نورة  الحربي', of(ExportRange.last7)),
        'tafaqod-نورة-الحربي-2026-11-03-2026-11-09.pdf',
      );
    });

    test('falls back to «record» without a patient', () {
      expect(
        exportFilename(null, of(ExportRange.last7)),
        startsWith('tafaqod-record-'),
      );
    });
  });
}
