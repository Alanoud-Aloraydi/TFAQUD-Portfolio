import 'package:app/core/utils/hijri/umm_al_qura_table.dart';
import 'package:equatable/equatable.dart';

/// A day of the Umm al-Qura calendar: [month] 1 (محرم) to 12 (ذو الحجة).
class HijriDate extends Equatable {
  const HijriDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  /// The Hijri day of [date]'s year, month and day (its time is ignored);
  /// null outside the table, before 1924 or after 2077.
  static HijriDate? of(DateTime date) {
    final int rjd = _rjdOf(date);
    final List<int> starts = monthStarts;
    if (rjd < starts.first || rjd >= starts.last) return null;
    // The last month that starts on or before the day.
    int low = 0;
    int high = starts.length - 2;
    while (low < high) {
      final int middle = (low + high + 1) ~/ 2;
      if (starts[middle] <= rjd) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    final int months = low + monthsBeforeTable;
    return HijriDate(months ~/ 12 + 1, months % 12 + 1, rjd - starts[low] + 1);
  }

  /// The Gregorian day of this Hijri day, at midnight on the phone's
  /// calendar; null outside the table or past the month's last day.
  DateTime? toGregorian() {
    final int? length = monthLength(year, month);
    if (length == null || day < 1 || day > length) return null;
    final int rjd = monthStarts[_indexOf(year, month)] + day - 1;
    final DateTime utc = _epoch.add(Duration(days: rjd - 1));
    return DateTime(utc.year, utc.month, utc.day);
  }

  /// The days of Hijri [year]'s [month]: 29 or 30 (a few odd months before
  /// 1365 differ); null outside the table.
  static int? monthLength(int year, int month) {
    final int index = _indexOf(year, month);
    if (month < 1 || month > 12) return null;
    if (index < 0 || index >= monthStarts.length - 1) return null;
    return monthStarts[index + 1] - monthStarts[index];
  }

  static int _indexOf(int year, int month) =>
      (year - 1) * 12 + month - 1 - monthsBeforeTable;

  /// Reduced Julian day 1.
  static final DateTime _epoch = DateTime.utc(1858, 11, 17);

  static int _rjdOf(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays +
      1;

  @override
  List<Object?> get props => [year, month, day];
}
