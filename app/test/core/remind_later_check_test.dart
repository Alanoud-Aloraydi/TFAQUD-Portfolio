import 'dart:async';

import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/app/widgets/remind_later_check.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../support/phone_fakes.dart';
import '../support/widget_harness.dart';

void main() {
  late FakeDoseReminders reminders;
  late List<bool> answers;

  setUp(() async {
    await GetIt.I.reset();
    reminders = FakeDoseReminders();
    GetIt.I.registerSingleton<DoseReminders>(reminders);
    answers = <bool>[];
  });
  tearDown(() => GetIt.I.reset());

  /// Presses a «ذكّرني لاحقًا» that first asks [mayRemindLater].
  Future<void> pressLater(WidgetTester tester) async {
    await pumpArabic(
      tester,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () =>
                unawaited(mayRemindLater(context).then(answers.add)),
            child: const Text('later'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('later'));
    await tester.pumpAndSettle();
  }

  testWidgets('with the notifications on, «ذكّرني لاحقًا» goes on', (
    WidgetTester tester,
  ) async {
    await pressLater(tester);

    expect(answers, <bool>[true]);
    expect(find.text('reminders.snooze_off'.tr()), findsNothing);
  });

  testWidgets('with the notifications off, it says why and puts nothing '
      'off', (WidgetTester tester) async {
    reminders.remindLater = false;

    await pressLater(tester);

    expect(answers, <bool>[false]);
    expect(find.text('reminders.snooze_off'.tr()), findsOneWidget);
  });
}
