import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/reminders/dose_reminders.dart'
    show TaskSnooze;
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/data/simplified_preferences.dart';
import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_reminder_screen.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/simplified_fakes.dart';
import '../support/widget_harness.dart';

/// 11:30 blood pressure, due before the patient's noon.
final MeasurementOccurrence _pressure = MeasurementOccurrence(
  planId: 'm-1',
  versionId: 'v-1',
  kind: MeasurementKind.bp,
  scheduledOn: DateTime(2026, 11, 9),
  time: '11:30',
  deadlineAt: DateTime.utc(2026, 11, 9, 12),
  status: MeasurementStatus.due,
);

/// A day with that one measurement.
class _UseCase implements SimplifiedModeUseCase {
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
      doses: const [],
      measurements: <MeasurementOccurrence>[_pressure],
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SimplifiedReminderRoutes', () {
    setUpAll(initTestLocalization);
    setUp(
      () => GetIt.I.registerSingleton<SimplifiedVoice>(FakeSimplifiedVoice()),
    );
    tearDown(() => GetIt.I.unregister<SimplifiedVoice>());

    // The cubit ticks every minute. A test closes it in its own fake time,
    // before the binding checks for pending timers; a tear-down runs only
    // after that check, and outside that fake time.
    late SimplifiedModeCubit cubit;

    /// The reminder for the pressure reading, with the two pages it leads to
    /// writing the `extra` they were given.
    Future<ValueNotifier<Object?>> open(WidgetTester tester) async {
      final ValueNotifier<Object?> arrived = ValueNotifier<Object?>(null);
      cubit = SimplifiedModeCubit(_UseCase(), clock: () => noonInRiyadh);
      await cubit.load();
      final GoRouter router = GoRouter(
        initialLocation: Routes.simplifiedReminder,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.simplifiedReminder,
            builder: (context, state) => MultiBlocProvider(
              providers: <BlocProvider<dynamic>>[
                BlocProvider<SimplifiedModeCubit>.value(value: cubit),
                BlocProvider<SimplifiedSettingsCubit>(
                  create: (_) =>
                      SimplifiedSettingsCubit(SimplifiedPreferences())..load(),
                ),
              ],
              child: const SimplifiedReminderScreen(
                request: ReminderRequest(TodayTaskKind.measurement),
              ),
            ),
          ),
          GoRoute(
            path: Routes.simplifiedMeasurePath,
            builder: (context, state) {
              arrived.value = (
                'measure',
                state.pathParameters['circleId'],
                state.extra,
              );
              return const Text('measure page');
            },
          ),
          GoRoute(
            path: Routes.simplifiedSnooze,
            builder: (context, state) {
              arrived.value = ('snooze', null, state.extra);
              return const Text('snooze page');
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await pumpArabic(tester, router: router);
      return arrived;
    }

    /// Taps the word [label] under its round answer, as an elderly user
    /// often does: the word is part of the answer's tap area.
    Future<void> answer(WidgetTester tester, String label) async {
      final Finder word = find.descendant(
        of: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics && widget.properties.label == label,
        ),
        matching: find.text(label),
      );
      await tester.ensureVisible(word);
      await tester.pumpAndSettle();
      await tester.tap(word);
      await tester.pumpAndSettle();
    }

    testWidgets('«أقيس الآن» opens the measure page of the circle with the '
        'reading chosen', (tester) async {
      final ValueNotifier<Object?> arrived = await open(tester);

      await answer(tester, 'simplified_mode.measure_now'.tr());

      expect(arrived.value, ('measure', 'c-1', _pressure));
      expect(find.text('measure page'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('«ذكّرني لاحقًا» opens the snooze page with the same task', (
      tester,
    ) async {
      final ValueNotifier<Object?> arrived = await open(tester);

      await answer(tester, 'simplified_mode.remind_later'.tr());

      final (String page, Object? _, Object? extra) =
          arrived.value! as (String, String?, Object?);
      expect(page, 'snooze');
      expect((extra! as TodayTask).measurement, _pressure);
      expect(find.text('snooze page'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('«بعد كذا» is counted on the patient clock, not the phone', (
      tester,
    ) async {
      late String until;
      await pumpArabic(
        tester,
        clock: PatientClock('Europe/London'),
        home: Builder(
          builder: (context) {
            // 12:00 UTC on 1 July is 13:00 in London; 14:00 is an hour away.
            until = simplifiedUntil(
              context,
              DateTime.utc(2026, 7, 1, 14),
              DateTime.utc(2026, 7, 1, 12),
            );
            return const SizedBox();
          },
        ),
      );

      expect(until, isNot('simplified_mode.now'.tr()));
      expect(
        PatientClockScope.of(tester.element(find.byType(SizedBox))).zone,
        'Europe/London',
      );
    });
  });
}
