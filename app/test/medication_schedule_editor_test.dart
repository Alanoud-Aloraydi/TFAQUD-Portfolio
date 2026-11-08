import 'dart:convert';
import 'dart:io';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Translations extends AssetLoader {
  const _Translations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/ar.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// [count] days as the app says them: «يوم», «يومين», «3 أيام», «11 يوم».
String arabicDays(int count) => switch (count) {
  1 => 'يوم',
  2 => 'يومين',
  <= 10 => '$count أيام',
  _ => '$count يوم',
};

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<ScheduleFormData> openEditor(
    WidgetTester tester,
    double dose, {
    DateTime? startsOn,
  }) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = ScheduleFormData(
      time: const TimeOfDay(hour: 8, minute: 0),
      dose: dose,
      weekdays: {1, 2, 3, 4, 5, 6, 7},
      doseUnit: DoseUnit.tablet,
    );
    addTearDown(data.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        startLocale: const Locale('ar'),
        path: 'assets/translations',
        assetLoader: const _Translations(),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.lightTheme,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => MedicationScheduleEditor(
                  index: 0,
                  data: data,
                  units: const [DoseUnit.tablet],
                  startsOn: startsOn,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return data;
  }

  testWidgets('tablet stepper advances by halves and stops at its minimum', (
    tester,
  ) async {
    final data = await openEditor(tester, 0.5);
    final decrement = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.tooltip == 'medications.dose_less'.tr(),
    );
    expect(tester.widget<IconButton>(decrement).onPressed, isNull);
    await tester.tap(find.byTooltip('medications.dose_more'.tr()));
    await tester.pump();
    expect(data.doseController.text, '1');
    await tester.tap(decrement);
    await tester.pump();
    expect(data.doseController.text, '0.5');
    expect(tester.takeException(), isNull);
  });

  // The week is seven day chips, all on for every day; there is no
  // separate "every day" chip.
  testWidgets('a day chip takes its day out of the week and back', (
    tester,
  ) async {
    final data = await openEditor(tester, 1);
    // The chip, not its letter: the chip takes the tap.
    final sunday = find.widgetWithText(
      FilterChip,
      'medications.weekday_short.7'.tr(),
    );
    await tester.tap(sunday);
    await tester.pump();
    expect(data.weekdays, {1, 2, 3, 4, 5, 6});
    await tester.tap(sunday);
    await tester.pump();
    expect(data.weekdays, {1, 2, 3, 4, 5, 6, 7});
    expect(tester.takeException(), isNull);
  });

  testWidgets('«كل كم يوم» sets the days on a ruler, «أسبوعي» the week', (
    tester,
  ) async {
    final data = await openEditor(
      tester,
      1,
      startsOn: DateTime(2026, 11, 1),
    );

    await tester.tap(find.text('medications.repeat_interval'.tr()));
    await tester.pumpAndSettle();
    expect(data.repeat, ScheduleRepeat.interval);
    // Every other day to start, said the Arabic way.
    expect(data.intervalDays, 2);
    expect(find.text(arabicDays(2)), findsOneWidget);
    expect(find.text('medications.weekday_short.7'.tr()), findsNothing);
    expect(find.textContaining('1 نوفمبر 2026'), findsOneWidget);

    // VoiceOver reads the ruler as a slider and moves it one day at a time.
    final ruler = find.bySemanticsLabel('عدد الأيام');
    expect(
      tester.getSemantics(ruler),
      isSemantics(
        isSlider: true,
        value: 'يومين',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    // VoiceOver's swipe up.
    tester
        .widget<Semantics>(
          find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.slider == true,
          ),
        )
        .properties
        .onIncrease!();
    await tester.pumpAndSettle();
    expect(data.intervalDays, 3);
    expect(find.text(arabicDays(3)), findsOneWidget);

    await tester.tap(find.text('medications.repeat_weekly'.tr()));
    await tester.pumpAndSettle();
    expect(data.repeat, ScheduleRepeat.weekly);
    expect(data.weekdays, {1, 2, 3, 4, 5, 6, 7});
    // The number of days stays, for switching back.
    expect(data.intervalDays, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging the ruler picks a number of days', (tester) async {
    final data = await openEditor(tester, 1);
    await tester.tap(find.text('medications.repeat_interval'.tr()));
    await tester.pumpAndSettle();

    // Arabic reads right to left: the larger numbers come from the left.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(data.intervalDays, greaterThan(2));
    expect(find.text(arabicDays(data.intervalDays)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
