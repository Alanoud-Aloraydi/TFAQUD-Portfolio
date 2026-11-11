import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/widgets/forms/missed_after_field.dart';
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
    testWidgets('starts with the stored minutes and no error', (tester) async {
      await pumpArabic(tester, home: _Host(<int?>[]));
      expect(find.text('60'), findsOneWidget);
      expect(find.text(_range), findsNothing);
    });

    testWidgets('any number inside the range is passed on', (tester) async {
      final List<int?> log = <int?>[];
      await pumpArabic(tester, home: _Host(log));
      await tester.enterText(find.byType(TextField), '45');
      await tester.pump();
      expect(log.last, 45);
      expect(find.text(_range), findsNothing);
    });

    testWidgets('a number above 360 is passed on and the range is shown', (
      tester,
    ) async {
      final List<int?> log = <int?>[];
      await pumpArabic(tester, home: _Host(log));
      await tester.enterText(find.byType(TextField), '400');
      await tester.pump();
      expect(log.last, 400);
      expect(find.text(_range), findsOneWidget);
    });

    testWidgets('an emptied field passes null and shows the range', (
      tester,
    ) async {
      final List<int?> log = <int?>[];
      await pumpArabic(tester, home: _Host(log));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(log.last, isNull);
      expect(find.text(_range), findsOneWidget);
    });

    testWidgets('showError shows the range before anything is typed', (
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

    testWidgets('letters and signs cannot be typed', (tester) async {
      final List<int?> log = <int?>[];
      await pumpArabic(tester, home: _Host(log));
      await tester.enterText(find.byType(TextField), '1a-5');
      await tester.pump();
      expect(log.last, 15);
    });
  });
}
