import '../support/widget_harness.dart';

import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/utils/calendar_day.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:app/core/widgets/pickers/date_wheel_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the wheel on 19 November 2026 (9 جمادى الآخرة 1448) and keeps
/// what it confirms.
Future<List<DateTime?>> _open(
  WidgetTester tester, {
  required bool offerCalendars,
}) async {
  final List<DateTime?> confirmed = <DateTime?>[];
  await pumpArabic(
    tester,
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () async => confirmed.add(
            await Navigator.of(context).push<DateTime>(
              MaterialPageRoute<DateTime>(
                builder: (_) => Scaffold(
                  body: DateWheelSheet(
                    initialDate: DateTime(2026, 11, 19),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2030),
                    calendar: DateCalendar.hijri,
                    offerCalendars: offerCalendars,
                  ),
                ),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return confirmed;
}

void main() {
  setUpAll(initTestLocalization);

  test('a Hijri month offers its own days', () {
    final DateWheelRanges ranges = DateWheelRanges(
      first: calendarDayOf(DateTime(2026), DateCalendar.hijri),
      last: calendarDayOf(DateTime(2030), DateCalendar.hijri),
      year: 1448,
      month: 6,
      calendar: DateCalendar.hijri,
    );
    expect(ranges.days.last, 29);
    expect(ranges.months, hasLength(12));
  });

  testWidgets('the wheel turns in Hijri and gives back the same day', (
    WidgetTester tester,
  ) async {
    final List<DateTime?> confirmed = await _open(
      tester,
      offerCalendars: false,
    );

    expect(find.text('calendar.hijri_months.6'.tr()), findsWidgets);
    expect(find.text('1448'), findsWidgets);
    await tester.tap(find.text('common.confirm'.tr()));
    await tester.pumpAndSettle();

    expect(confirmed, <DateTime?>[DateTime(2026, 11, 19)]);
  });

  testWidgets('a birth date offers both calendars and shows the other one', (
    WidgetTester tester,
  ) async {
    await _open(tester, offerCalendars: true);
    expect(
      find.text(
        'calendar.matches'.tr(
          args: <String>[
            '19 ${'circles.months.11'.tr()} 2026 '
                '${'calendar.era.gregorian'.tr()}',
          ],
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('calendar.gregorian'.tr()));
    await tester.pumpAndSettle();

    expect(find.text('circles.months.11'.tr()), findsWidgets);
    expect(
      find.text(
        'calendar.matches'.tr(
          args: <String>[
            '9 ${'calendar.hijri_months.6'.tr()} 1448 '
                '${'calendar.era.hijri'.tr()}',
          ],
        ),
      ),
      findsOneWidget,
    );
  });
}
