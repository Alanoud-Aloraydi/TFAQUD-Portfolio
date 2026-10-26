import 'package:app/features/circles/domain/birth_date_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 26);

  group('days in a month', () {
    test('follow the calendar, with leap years', () {
      expect(BirthDateRules.daysInMonth(2025, 2), 28);
      expect(BirthDateRules.daysInMonth(2024, 2), 29);
      expect(BirthDateRules.daysInMonth(1900, 2), 28);
      expect(BirthDateRules.daysInMonth(2000, 2), 29);
      expect(BirthDateRules.daysInMonth(2025, 4), 30);
      expect(BirthDateRules.daysInMonth(2025, 12), 31);
    });
  });

  group('limits of today', () {
    test('this year stops at this month, other years go to December', () {
      expect(BirthDateRules.lastMonth(2026, today), 10);
      expect(BirthDateRules.lastMonth(2025, today), 12);
    });

    test('this month stops at today, other months go to their last day', () {
      expect(BirthDateRules.lastDay(2026, 10, today), 26);
      expect(BirthDateRules.lastDay(2026, 9, today), 30);
      expect(BirthDateRules.lastDay(2025, 10, today), 31);
    });
  });

  group('clamp', () {
    test('keeps a valid date', () {
      expect(
        BirthDateRules.clamp(1964, 3, 12, today),
        DateTime(1964, 3, 12),
      );
    });

    test('moves a day that the new month does not have', () {
      expect(BirthDateRules.clamp(2025, 4, 31, today), DateTime(2025, 4, 30));
      expect(BirthDateRules.clamp(2023, 2, 29, today), DateTime(2023, 2, 28));
      expect(BirthDateRules.clamp(2024, 2, 29, today), DateTime(2024, 2, 29));
    });

    test('never goes past today', () {
      expect(BirthDateRules.clamp(2026, 12, 31, today), DateTime(2026, 10, 26));
      expect(BirthDateRules.clamp(2030, 1, 1, today), DateTime(2026, 1, 1));
      expect(BirthDateRules.clamp(2026, 10, 27, today), DateTime(2026, 10, 26));
    });

    test('never goes before the first year', () {
      expect(BirthDateRules.clamp(1850, 1, 1, today), DateTime(1900, 1, 1));
    });
  });

  group('lists', () {
    test('years start with this year and end with 1900', () {
      final List<int> years = BirthDateRules.years(today);
      expect(years.first, 2026);
      expect(years.last, 1900);
      expect(years, hasLength(127));
    });

    test('months and days follow the limits', () {
      expect(BirthDateRules.months(2026, today), hasLength(10));
      expect(BirthDateRules.months(2025, today), hasLength(12));
      expect(BirthDateRules.days(2026, 10, today), hasLength(26));
      expect(BirthDateRules.days(2024, 2, today), hasLength(29));
    });
  });
}
