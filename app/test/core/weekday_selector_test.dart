import 'package:app/core/l10n/weekdays_text.dart';
import 'package:app/core/utils/weekdays.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

class _Host extends StatefulWidget {
  const _Host(this.start, this.log);

  final Set<int> start;
  final List<Set<int>> log;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late Set<int> _days = widget.start;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: WeekdaySelector(
      selected: _days,
      onChanged: (Set<int> days) {
        widget.log.add(days);
        setState(() => _days = days);
      },
    ),
  );
}

String _short(int day) => 'medications.weekday_short.$day'.tr();

void main() {
  setUpAll(initTestLocalization);

  group('WeekdaySelector', () {
    testWidgets('shows «كل الأيام» and the seven days', (tester) async {
      await pumpArabic(tester, home: _Host(allWeekdays, <Set<int>>[]));
      expect(find.text('weekday_picker.all_days'.tr()), findsOneWidget);
      for (final int day in weekOrder) {
        expect(find.text(_short(day)), findsOneWidget);
      }
    });

    testWidgets('a day with the full week on picks that day alone', (
      tester,
    ) async {
      final List<Set<int>> log = <Set<int>>[];
      await pumpArabic(tester, home: _Host(allWeekdays, log));
      await tester.tap(find.text(_short(3)));
      await tester.pump();
      expect(log.single, <int>{3});
    });

    testWidgets('«كل الأيام» selects the whole week again', (tester) async {
      final List<Set<int>> log = <Set<int>>[];
      await pumpArabic(tester, home: _Host(<int>{1}, log));
      await tester.tap(find.text('weekday_picker.all_days'.tr()));
      await tester.pump();
      expect(isEveryDay(log.single), isTrue);
    });

    testWidgets('a box is a selected button for VoiceOver', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpArabic(tester, home: _Host(<int>{1}, <Set<int>>[]));
      final String label = 'medications.weekday.1'.tr();
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(
          label: label,
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('every box is at least 44 high', (tester) async {
      await pumpArabic(tester, home: _Host(<int>{1}, <Set<int>>[]));
      final Size box = tester.getSize(
        find.ancestor(of: find.text(_short(1)), matching: find.byType(InkWell)),
      );
      expect(box.height, greaterThanOrEqualTo(44));
    });
  });

  group('WeekdayStrip and formatWeekdays', () {
    testWidgets('the full week reads «كل يوم»', (tester) async {
      late String words;
      await pumpArabic(
        tester,
        home: Builder(
          builder: (BuildContext context) {
            words = formatWeekdays(context, allWeekdays);
            return Scaffold(body: WeekdayStrip(days: allWeekdays));
          },
        ),
      );
      expect(words, 'weekday_picker.every_day'.tr());
      expect(find.text('weekday_picker.every_day'.tr()), findsOneWidget);
      expect(find.text(_short(1)), findsNothing);
    });

    testWidgets('some days show the week, named from Saturday', (tester) async {
      late String words;
      await pumpArabic(
        tester,
        home: Builder(
          builder: (BuildContext context) {
            words = formatWeekdays(context, <int>[1, 6]);
            return const Scaffold(body: WeekdayStrip(days: <int>[1, 6]));
          },
        ),
      );
      expect(find.text('weekday_picker.every_day'.tr()), findsNothing);
      for (final int day in weekOrder) {
        expect(find.text(_short(day)), findsOneWidget);
      }
      expect(words.startsWith('medications.weekday.6'.tr()), isTrue);
    });
  });
}
