import 'dart:async';

import 'package:app/core/widgets/layout/pull_to_refresh.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// A main page too short to scroll, as «اليوم» is on a quiet day.
Widget _page({Future<void> Function()? onRefresh}) {
  final Widget page = Scaffold(
    body: PullToRefresh(
      child: ListView(children: const <Widget>[Text('جدول اليوم')]),
    ),
  );
  return onRefresh == null
      ? page
      : RefreshScope(onRefresh: onRefresh, child: page);
}

Future<void> _pullDown(WidgetTester tester) async {
  await tester.fling(find.text('جدول اليوم'), const Offset(0, 300), 1000);
  await tester.pump();
  // The scroll settles, the loader turns, «تم التحديث», then it closes.
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(initTestLocalization);

  group('PullToRefresh', () {
    testWidgets('a main page pulled down from its top reads it all again, '
        'even when it is too short to scroll', (tester) async {
      int reads = 0;
      await pumpArabic(
        tester,
        home: _page(
          onRefresh: () async {
            reads++;
          },
        ),
      );

      await _pullDown(tester);

      expect(reads, 1);
    });

    testWidgets('a part with its own data hears every pull, to read it '
        'again in its place', (tester) async {
      int heard = 0;
      Listenable? pulls;
      await pumpArabic(
        tester,
        home: RefreshScope(
          onRefresh: () async {},
          child: Scaffold(
            body: PullToRefresh(
              child: Builder(
                builder: (BuildContext context) {
                  pulls ??= RefreshScope.pullsOf(context)
                    ?..addListener(() => heard++);
                  return ListView(children: const <Widget>[Text('جدول اليوم')]);
                },
              ),
            ),
          ),
        ),
      );

      await _pullDown(tester);
      await _pullDown(tester);

      expect(heard, 2);
    });

    testWidgets('it goes as in the video: pull, let go, held open while '
        'it reads, «تم التحديث», then closed', (tester) async {
      final Completer<void> reading = Completer<void>();
      await pumpArabic(tester, home: _page(onRefresh: () => reading.future));
      final Finder row = find.text('جدول اليوم');
      final double rest = tester.getTopLeft(row).dy;

      final TestGesture finger = await tester.startGesture(
        tester.getCenter(row),
      );
      await finger.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(find.text('refresh.pull'.tr()), findsOneWidget);
      await finger.moveBy(const Offset(0, 300));
      await tester.pump();
      expect(find.text('refresh.release'.tr()), findsOneWidget);

      await finger.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('refresh.loading'.tr()), findsOneWidget);
      // Still open over the loader while it reads.
      expect(tester.getTopLeft(row).dy, greaterThan(rest + 40));

      reading.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('refresh.done'.tr()), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('refresh.done'.tr()), findsNothing);
      expect(tester.getTopLeft(row).dy, moreOrLessEquals(rest));
    });

    testWidgets('outside the home shell it leaves the page alone', (
      tester,
    ) async {
      await pumpArabic(tester, home: _page());

      expect(find.byType(RefreshHeader), findsNothing);
      await _pullDown(tester);
      expect(find.text('جدول اليوم'), findsOneWidget);
    });
  });
}
