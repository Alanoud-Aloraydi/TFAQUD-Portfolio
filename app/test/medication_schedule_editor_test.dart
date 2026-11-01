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

  Future<ScheduleFormData> openEditor(WidgetTester tester, double dose) async {
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

  testWidgets('every-day chip clears and restores the whole week', (
    tester,
  ) async {
    final data = await openEditor(tester, 1);
    final everyDay = find.text('medications.every_day'.tr());
    await tester.tap(everyDay);
    await tester.pump();
    expect(data.weekdays, isEmpty);
    await tester.tap(everyDay);
    await tester.pump();
    expect(data.weekdays, {1, 2, 3, 4, 5, 6, 7});
    expect(tester.takeException(), isNull);
  });
}
