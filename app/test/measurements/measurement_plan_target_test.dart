import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_targets_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/widget_harness.dart';

/// A circle whose blood pressure target comes from a plan, and whose
/// glucose target is free.
class _Measurements extends Fake implements MeasurementRepository {
  @override
  Stream<String> get recorded => const Stream<String>.empty();

  @override
  Future<List<MeasurementTarget>> targets(String circleId) async =>
      const <MeasurementTarget>[
        MeasurementTarget(
          kind: MeasurementKind.bp,
          systolicLimit: 140,
          diastolicLimit: 90,
          planId: 'plan-1',
        ),
      ];

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

  /// A free reading's sheet, opened over a page of the circle.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _Measurements repository = _Measurements();
    final MeasurementReadingsCubit readings = MeasurementReadingsCubit(
      repository,
    );
    final MeasurementTargetsCubit targets = MeasurementTargetsCubit(repository);
    addTearDown(readings.close);
    addTearDown(targets.close);
    await readings.load(
      'circle-1',
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 10),
    );
    await targets.load('circle-1');
    final GoRouter router = GoRouter(
      initialLocation: '/circle',
      routes: <RouteBase>[
        GoRoute(
          path: '/circle',
          builder: (context, state) => const Scaffold(body: Text('circle')),
        ),
        GoRoute(
          path: '/sheet',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: readings),
              BlocProvider.value(value: targets),
            ],
            child: const Scaffold(body: MeasurementReadingSheet()),
          ),
        ),
        GoRoute(
          path: Routes.measurementEditPath,
          builder: (context, state) =>
              Scaffold(body: Text('plan ${state.pathParameters['planId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('ar')],
        startLocale: const Locale('ar'),
        path: 'assets/translations',
        assetLoader: const TestTranslations(),
        child: Builder(
          builder: (context) => MaterialApp.router(
            theme: AppTheme.lightTheme,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/sheet').ignore();
    await tester.pumpAndSettle();
  }

  testWidgets('a target from a plan says so, under the fields', (tester) async {
    await open(tester);

    expect(find.text('measurements.plan_target_hint'.tr()), findsOneWidget);
    expect(find.text('measurements.free_target_hint'.tr()), findsNothing);
  });

  testWidgets('«تعديل الهدف في الخطة» is a row that opens the plan', (
    tester,
  ) async {
    await open(tester);

    final Finder edit = find.text('measurements.edit_plan_target'.tr());
    expect(edit, findsOneWidget);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    expect(find.text('plan plan-1'), findsOneWidget);
    expect(find.byType(MeasurementReadingSheet), findsNothing);
  });
}
