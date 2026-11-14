import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/simplified_mode/data/simplified_preferences.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_snooze_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/widget_harness.dart';

/// 12:00 in Riyadh on 9 November 2026.
final DateTime _noon = DateTime.utc(2026, 11, 9, 9);

DoseOccurrence _dose(String time) => DoseOccurrence(
  planId: 'p-$time',
  scheduleId: 's-$time',
  scheduledOn: DateTime(2026, 11, 9),
  time: time,
  name: 'ميتفورمين',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

/// A day of two doses due, and what was put off.
class _UseCase implements SimplifiedModeUseCase {
  final List<(TodayTask, Duration)> snoozed = <(TodayTask, Duration)>[];
  final ValueNotifier<Map<String, TaskSnooze>> _snoozes =
      ValueNotifier<Map<String, TaskSnooze>>(const <String, TaskSnooze>{});

  @override
  Future<Result<SimplifiedDay, Failure>> loadDay(DateTime now) async => Success(
    SimplifiedDay(
      circleId: 'c-1',
      circleName: 'دائرتي',
      accountId: 'a-1',
      isPatient: true,
      displayName: 'مريم',
      timeZone: 'Asia/Riyadh',
      doses: <DoseOccurrence>[_dose('08:00'), _dose('11:30')],
      measurements: const <MeasurementOccurrence>[],
      appointments: const [],
      family: const [],
      reasons: const <String, String>{},
    ),
  );

  @override
  Future<void> keepReminding(SimplifiedDay day) async {}

  @override
  ValueListenable<Map<String, TaskSnooze>> get snoozes => _snoozes;

  @override
  Future<void> snooze(String circleId, TodayTask task, Duration after) async =>
      snoozed.add((task, after));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// «بعد ١٥ دقيقة» as the app says it.
String _after15() => 'simplified_mode.after_15'.tr();

/// «رجوع» as the app says it.
String _back() => 'simplified_mode.back'.tr();

void main() {
  group('SimplifiedSnoozeScreen', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await EasyLocalization.ensureInitialized();
    });

    /// The snooze screen for the 08:00 dose (not the most recent one due,
    /// 11:30), on a small phone at text size [scale]. Each test closes the
    /// cubit, whose minute ticker would otherwise outlive it.
    Future<(_UseCase, TodayTask, SimplifiedModeCubit)> open(
      WidgetTester tester,
      double scale,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final _UseCase useCase = _UseCase();
      final SimplifiedModeCubit cubit = SimplifiedModeCubit(
        useCase,
        clock: () => _noon,
      );
      await cubit.load();
      final TodayTask chosen = cubit.state.schedule!.tasks.first;
      final GoRouter router = GoRouter(
        initialLocation: '/snooze',
        routes: <RouteBase>[
          GoRoute(
            path: '/simplifiedMode',
            builder: (context, state) => const Text('home'),
          ),
          GoRoute(
            path: '/snooze',
            builder: (context, state) => SimplifiedSnoozeScreen(task: chosen),
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
            builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider<SimplifiedModeCubit>.value(value: cubit),
                BlocProvider<SimplifiedSettingsCubit>(
                  create: (_) =>
                      SimplifiedSettingsCubit(SimplifiedPreferences())..load(),
                ),
              ],
              child: MaterialApp.router(
                theme: AppTheme.lightTheme,
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (useCase, chosen, cubit);
    }

    testWidgets('puts off the dose the patient chose, then goes home', (
      tester,
    ) async {
      final (_UseCase useCase, TodayTask chosen, SimplifiedModeCubit cubit) =
          await open(tester, 1);

      await tester.tap(find.text(_after15()));
      await tester.pumpAndSettle();

      expect(useCase.snoozed.single, (chosen, const Duration(minutes: 15)));
      expect(find.text('home'), findsOneWidget);
      await cubit.close();
    });

    for (final double scale in <double>[1.3, 2]) {
      testWidgets('every choice and «رجوع» show at text size $scale', (
        tester,
      ) async {
        final (_, _, SimplifiedModeCubit cubit) = await open(tester, scale);

        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text(_back()), 100);
        expect(find.text(_back()), findsOneWidget);
        await cubit.close();
      });
    }

    testWidgets('each choice is one labelled button', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final (_, _, SimplifiedModeCubit cubit) = await open(tester, 1);

      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(_after15()))),
        findsOneWidget,
      );
      semantics.dispose();
      await cubit.close();
    });
  });
}
