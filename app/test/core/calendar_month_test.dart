import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final CalendarMonth jumadaII = CalendarMonth.of(
    DateTime(2026, 11, 19),
    DateCalendar.hijri,
  );

  group('CalendarMonth', () {
    test('a Hijri month is the Gregorian days it covers', () {
      expect((jumadaII.year, jumadaII.month), (1448, 6));
      expect(jumadaII.first, DateTime(2026, 11, 11));
      expect(jumadaII.days, 29);
      expect(jumadaII.last, DateTime(2026, 12, 9));
      expect(jumadaII.numberOf(DateTime(2026, 11, 19)), 9);
      expect(jumadaII.numberOf(DateTime(2026, 12, 10)), isNull);
    });

    test('moves a month at a time, both ways', () {
      expect(jumadaII.shift(-1).first, DateTime(2026, 10, 12));
      expect(jumadaII.shift(-1).days, 30);
      expect(jumadaII.shift(1).first, DateTime(2026, 12, 10));
      expect(jumadaII.shift(1).isAfter(jumadaII), isTrue);
    });

    test('a Gregorian month is its own days', () {
      final CalendarMonth november = CalendarMonth.of(
        DateTime(2026, 11, 19),
        DateCalendar.gregorian,
      );
      expect(november.first, DateTime(2026, 11));
      expect(november.days, 30);
      expect(november.shift(-11).first, DateTime(2025, 12));
    });
  });

  test('the history filter groups by Hijri months', () {
    final List<DateTime> days = <DateTime>[
      DateTime(2026, 11, 12),
      DateTime(2026, 11, 5),
      DateTime(2026, 10, 30),
    ];

    final List<DateTime> months = HistoryFilter.monthsOf(
      days,
      calendar: DateCalendar.hijri,
    );
    final HistoryFilter filter = HistoryFilter.all.withMonth(months.last);

    expect(months, <DateTime>[DateTime(2026, 11, 11), DateTime(2026, 10, 12)]);
    expect(
      days.where(
        (DateTime day) =>
            filter.shows(day, (null, null), calendar: DateCalendar.hijri),
      ),
      <DateTime>[DateTime(2026, 11, 5), DateTime(2026, 10, 30)],
    );
  });
}
