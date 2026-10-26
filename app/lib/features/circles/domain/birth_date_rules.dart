import 'dart:math' as math;

/// What the birth date sheet allows: from 1900 up to today, never a day that
/// has not come yet. Pure functions, so they can be tested without a screen.
abstract class BirthDateRules {
  BirthDateRules._();

  static const int firstYear = 1900;

  /// The number of days of [month] in [year] (28, 29, 30 or 31).
  static int daysInMonth(int year, int month) {
    // Day 0 of the next month is the last day of this month.
    return DateTime(year, month + 1, 0).day;
  }

  /// The last month that may be chosen in [year].
  static int lastMonth(int year, DateTime today) {
    return year == today.year ? today.month : 12;
  }

  /// The last day that may be chosen in [month] of [year].
  static int lastDay(int year, int month, DateTime today) {
    final int days = daysInMonth(year, month);
    if (year == today.year && month == today.month) {
      return math.min(days, today.day);
    }
    return days;
  }

  /// The date made of [year], [month] and [day], with each part moved back into
  /// what is allowed. Changing the year or the month can leave the day too
  /// high (31 in a 30-day month), and this fixes it.
  static DateTime clamp(int year, int month, int day, DateTime today) {
    final int y = math.min(math.max(year, firstYear), today.year);
    final int m = math.min(math.max(month, 1), lastMonth(y, today));
    final int d = math.min(math.max(day, 1), lastDay(y, m, today));
    return DateTime(y, m, d);
  }

  /// The years the sheet lists, the latest first.
  static List<int> years(DateTime today) {
    return <int>[for (int y = today.year; y >= firstYear; y--) y];
  }

  static List<int> months(int year, DateTime today) {
    return <int>[for (int m = 1; m <= lastMonth(year, today); m++) m];
  }

  static List<int> days(int year, int month, DateTime today) {
    return <int>[for (int d = 1; d <= lastDay(year, month, today); d++) d];
  }
}
