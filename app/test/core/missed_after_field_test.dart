import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

class _Host extends StatefulWidget {
  const _Host(this.log);

  final List<int?> log;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int? _minutes = PlanLimits.defaultMissedAfterMinutes;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: MissedAfterField(
      label: 'مهلة',
      minutes: _minutes,
      onChanged: (int? minutes) {
        widget.log.add(minutes);
        setState(() => _minutes = minutes);
      },
    ),
  );
}

String get _range => 'plan_limits.missed_after_range'.tr(
  args: <String>[
    '${PlanLimits.minMissedAfterMinutes}',
    '${PlanLimits.maxMissedAfterMinutes}',
  ],
);

void main() {
  setUpAll(initTestLocalization);

  group('PlanLimits', () {
    test('the range is 5 to 360 minutes, as the API and database say', () {
      expect(PlanLimits.minMissedAfterMinutes, 5);
      expect(PlanLimits.maxMissedAfterMinutes, 360);
      expect(PlanLimits.defaultMissedAfterMinutes, 60);
    });

    test('accepts the ends and refuses outside them', () {
      expect(PlanLimits.isValidMissedAfter(5), isTrue);
      expect(PlanLimits.isValidMissedAfter(45), isTrue);
      expect(PlanLimits.isValidMissedAfter(360), isTrue);
      expect(PlanLimits.isValidMissedAfter(4), isFalse);
      expect(PlanLimits.isValidMissedAfter(361), isFalse);
      expect(PlanLimits.isValidMissedAfter(null), isFalse);
    });
  });

  group('MissedAfterField', () {
    testWidgets('says the stored minutes in words, with no error', (
      tester,
    ) async {
      await pumpArabic(tester, home: _Host(<int?>[]));
      expect(
        find.text('counts.hours.one'.tr(args: <String>['1'])),
        findsOneWidget,
      );
      expect(find.text(_range), findsNothing);
    });

    testWidgets('opens the ruler of «ذكّرني لاحقًا», 5 to 360 minutes, and '
        'passes on what is chosen', (tester) async {
      final List<int?> log = <int?>[];
      await pumpArabic(tester, home: _Host(log));

      await tester.tap(find.text('مهلة'));
      await tester.pumpAndSettle();
      final RulerPicker ruler = tester.widget(find.byType(RulerPicker));
      expect((ruler.min, ruler.max, ruler.step), (5, 360, 5));
      ruler.onChanged(45);
      await tester.pump();
      expect(find.text(afterWords(45)), findsWidgets);
      await tester.tap(find.text('common.confirm'.tr()));
      await tester.pumpAndSettle();

      expect(log.last, 45);
      expect(
        find.text('counts.minutes.many'.tr(args: <String>['45'])),
        findsOneWidget,
      );
    });

    testWidgets('closing the ruler changes nothing', (tester) async {
      final List<int?> log = <int?>[];
      await pumpArabic(tester, home: _Host(log));

      await tester.tap(find.text('مهلة'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(log, isEmpty);
    });

    testWidgets('showError shows the range while nothing is chosen', (
      tester,
    ) async {
      await pumpArabic(
        tester,
        home: Scaffold(
          body: MissedAfterField(
            label: 'مهلة',
            minutes: null,
            showError: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text(_range), findsOneWidget);
    });
  });
}

/// «بعد 45 دقيقة», as the sheet says it.
String afterWords(int minutes) => 'today_dashboard.after'.tr(
  args: <String>[
    'counts.minutes.many'.tr(args: <String>['$minutes']),
  ],
);
