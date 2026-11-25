import '../support/widget_harness.dart';

import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/features/account/presentation/widgets/account_sections.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A date written under the scope, so it follows the choice.
class _Day extends StatelessWidget {
  const _Day();

  @override
  Widget build(BuildContext context) =>
      Text(calendarDate(context, DateTime(2026, 11, 19)), key: const Key('d'));
}

Future<void> _show(WidgetTester tester, Widget child) => pumpArabic(
  tester,
  home: CalendarScope(
    child: Scaffold(body: Column(children: <Widget>[const _Day(), child])),
  ),
);

String _day(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('d'))).data!;

void main() {
  setUpAll(initTestLocalization);
  setUp(() => AppCalendar.choice.value = DateCalendar.hijri);
  tearDown(() => AppCalendar.choice.value = DateCalendar.gregorian);

  testWidgets('every date follows «التاريخ» in «حسابي», at once, and the '
      'choice is kept on the phone', (WidgetTester tester) async {
    await _show(tester, const AccountCalendarCard());
    expect(_day(tester), '9 ${'calendar.hijri_months.6'.tr()} 1448');

    await tester.tap(find.text('calendar.gregorian'.tr()));
    await tester.pumpAndSettle();

    expect(_day(tester), '19 ${'circles.months.11'.tr()} 2026');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('date_calendar'), 'gregorian');
  });

  testWidgets('the simplified mode picks it with a big tile', (
    WidgetTester tester,
  ) async {
    await _show(
      tester,
      const SimplifiedCalendarTile(
        calendar: DateCalendar.gregorian,
        selected: false,
      ),
    );

    await tester.tap(find.text('calendar.gregorian'.tr()));
    await tester.pumpAndSettle();

    expect(AppCalendar.choice.value, DateCalendar.gregorian);
    expect(_day(tester), '19 ${'circles.months.11'.tr()} 2026');
  });
}
