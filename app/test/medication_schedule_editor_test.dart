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

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<ScheduleFormData> openEditor(
    WidgetTester tester,
    double dose, {
    int defaultMonthDay = 1,
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
                  defaultMonthDay: defaultMonthDay,
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
    final sunday = find.text('medications.weekday_short.7'.tr());
    await tester.tap(sunday);
    await tester.pump();
    expect(data.weekdays, {1, 2, 3, 4, 5, 6});
    await tester.tap(sunday);
    await tester.pump();
    expect(data.weekdays, {1, 2, 3, 4, 5, 6, 7});
    expect(tester.takeException(), isNull);
  });

  testWidgets('«شهري» shows the days 1 to 28, «أسبوعي» the week', (
    tester,
  ) async {
    final data = await openEditor(tester, 1);

    await tester.tap(find.text('medications.repeat_monthly'.tr()));
    await tester.pumpAndSettle();
    expect(data.repeat, ScheduleRepeat.monthly);
    // The first day chosen is the medicine's start day (1 by default).
    expect(data.monthDays, {1});
    expect(find.text('medications.weekday_short.7'.tr()), findsNothing);
    // Every month has the 28th; the 29th to the 31st are not offered.
    expect(find.text('28'), findsOneWidget);
    expect(find.text('29'), findsNothing);
    expect(find.text('31'), findsNothing);

    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.tap(find.text('28'));
    await tester.pump();
    expect(data.monthDays, {1, 15, 28});
    expect(
      tester.getSemantics(find.bySemanticsLabel('يوم 15 من الشهر')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );

    await tester.tap(find.text('medications.repeat_weekly'.tr()));
    await tester.pumpAndSettle();
    expect(data.repeat, ScheduleRepeat.weekly);
    expect(data.weekdays, {1, 2, 3, 4, 5, 6, 7});
    expect(find.text('28'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a medicine starting on the 30th starts monthly on the 28th', (
    tester,
  ) async {
    final data = await openEditor(tester, 1, defaultMonthDay: 30);

    await tester.tap(find.text('medications.repeat_monthly'.tr()));
    await tester.pumpAndSettle();

    expect(data.monthDays, {28});
  });
}
