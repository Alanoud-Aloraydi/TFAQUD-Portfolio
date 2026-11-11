import 'package:app/core/utils/overdue_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overdueStart', () {
    test('is two calendar days before the patient day', () {
      expect(overdueDays, 2);
      expect(overdueStart(DateTime(2026, 11, 11)), DateTime(2026, 11, 9));
    });

    test('ignores the time of day it is given', () {
      expect(
        overdueStart(DateTime(2026, 11, 11, 23, 59)),
        DateTime(2026, 11, 9),
      );
    });

    test('crosses month and year ends and a clock change day', () {
      expect(overdueStart(DateTime(2026, 1, 1)), DateTime(2025, 12, 30));
      expect(overdueStart(DateTime(2026, 3, 1)), DateTime(2026, 2, 27));
      expect(overdueStart(DateTime(2026, 3, 29)), DateTime(2026, 3, 27));
    });
  });
}
