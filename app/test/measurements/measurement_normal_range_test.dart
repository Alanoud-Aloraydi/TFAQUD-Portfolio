import '../support/normal_ranges.dart';
import '../support/widget_harness.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Measurements extends Fake implements MeasurementRepository {
  @override
  Stream<String> get recorded => const Stream<String>.empty();

  @override
  Future<NormalRanges> ranges(String circleId) async => generalRanges();

  @override
  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) async => const <MeasurementReading>[];
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  group('NormalRange', () {
    final NormalRanges ranges = generalRanges();

    test('a glucose value falls in the band that holds it', () {
      final NormalRange fasting = ranges.of(
        MeasurementKind.glucose,
        'fasting',
      )!;

      expect(fasting.levelOf(69), MeasurementLevel.low);
      expect(fasting.levelOf(100), MeasurementLevel.normal);
      expect(fasting.levelOf(125), MeasurementLevel.elevated);
      expect(fasting.levelOf(126), MeasurementLevel.high);
    });

    test('before a meal reads the fasting range; bedtime the one after', () {
      expect(
        ranges.of(MeasurementKind.glucose, 'before_meal')!.state,
        'fasting',
      );
      expect(
        ranges.of(MeasurementKind.glucose, 'bedtime')!.state,
        'after_meal',
      );
      expect(ranges.of(MeasurementKind.glucose)!.state, 'after_meal');
    });

    test('the worse blood pressure number decides, and high wins', () {
      final NormalRange pressure = ranges.of(MeasurementKind.bp)!;

      expect(pressure.levelOf(120, 80), MeasurementLevel.normal);
      expect(pressure.levelOf(121, 75), MeasurementLevel.elevated);
      expect(pressure.levelOf(110, 59), MeasurementLevel.low);
      expect(pressure.levelOf(150, 55), MeasurementLevel.high);
    });
  });

  group('the reading sheet', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final _Measurements repository = _Measurements();
      final MeasurementReadingsCubit readings = MeasurementReadingsCubit(
        MeasurementsUseCase(repository),
      );
      final MeasurementRangesCubit ranges = MeasurementRangesCubit(repository);
      addTearDown(readings.close);
      addTearDown(ranges.close);
      await readings.load(
        'circle-1',
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 10),
      );
      await ranges.load('circle-1');
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: AppTheme.lightTheme,
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: readings),
                  BlocProvider.value(value: ranges),
                ],
                child: const Scaffold(
                  // As in its glass sheet, which scrolls it.
                  body: SingleChildScrollView(child: MeasurementReadingSheet()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the normal range, not a target to type', (tester) async {
      await open(tester);

      expect(find.text('measurements.normal_range'.tr()), findsWidgets);
      expect(find.textContaining('90–120 / 60–80'), findsWidgets);
      expect(find.text('measurements.your_reading'.tr()), findsNothing);
    });

    testWidgets('marks where the typed value falls', (tester) async {
      await open(tester);

      final Finder fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '150');
      await tester.enterText(fields.at(1), '95');
      await tester.pumpAndSettle();

      expect(find.text('measurements.your_reading'.tr()), findsOneWidget);
      expect(find.text('measurements.level.high'.tr()), findsWidgets);
    });

    testWidgets('says the condition under the range, to change it', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('measurements.range_condition'.tr()), findsOneWidget);
      expect(
        find.text('measurements.range_profile.bp_general'.tr()),
        findsWidgets,
      );
      expect(find.text('measurements.range_from_file'.tr()), findsOneWidget);
    });

    testWidgets('a fasting glucose shows the fasting range', (tester) async {
      await open(tester);

      await tester.tap(find.text('measurements.glucose'.tr()));
      await tester.pumpAndSettle();
      expect(find.textContaining('70–140'), findsWidgets);

      await tester.tap(find.text('measurements.condition.fasting'.tr()));
      await tester.pumpAndSettle();
      expect(find.textContaining('70–100'), findsWidgets);
    });
  });
}
