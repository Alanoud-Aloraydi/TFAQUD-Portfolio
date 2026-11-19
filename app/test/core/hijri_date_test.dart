import 'package:app/core/utils/hijri/hijri_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HijriDate (Umm al-Qura)', () {
    test('reads the official dates', () {
      expect(HijriDate.of(DateTime(2026, 11, 19)), const HijriDate(1448, 6, 9));
      expect(HijriDate.of(DateTime(1954, 6, 5)), const HijriDate(1373, 10, 4));
      expect(HijriDate.of(DateTime(1924, 8)), const HijriDate(1343, 1, 1));
    });

    test('goes back to the same Gregorian day', () {
      for (
        DateTime day = DateTime(2025, 12, 1);
        day.isBefore(DateTime(2027, 2));
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        expect(HijriDate.of(day)!.toGregorian(), day);
      }
    });

    test('knows each month\'s length, the odd early ones too', () {
      expect(HijriDate.monthLength(1448, 5), 30);
      expect(HijriDate.monthLength(1448, 6), 29);
      expect(HijriDate.monthLength(1343, 9), 28);
      expect(const HijriDate(1448, 6, 30).toGregorian(), isNull);
    });

    test('has nothing outside the table', () {
      expect(HijriDate.of(DateTime(1924, 7, 31)), isNull);
      expect(HijriDate.of(DateTime(2077, 11, 17)), isNull);
      expect(HijriDate.monthLength(1501, 1), isNull);
    });
  });
}
