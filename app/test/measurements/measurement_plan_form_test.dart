import 'dart:async';

import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/widget_harness.dart';

/// No plans yet; remembers the plans the form saves.
class _Measurements extends Fake implements MeasurementRepository {
  final List<MeasurementPlanDraft> created = <MeasurementPlanDraft>[];

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<MeasurementPlan>> plans(String circleId) async =>
      const <MeasurementPlan>[];

  @override
  Future<MeasurementPlan> createPlan(
    String circleId,
    MeasurementPlanDraft draft,
  ) async {
    created.add(draft);
    return MeasurementPlan(
      id: 'plan-1',
      kind: draft.kind,
      version: MeasurementVersion(
        id: 'version-1',
        number: 1,
        effectiveFromOn: draft.startsOn,
        time: '07:30',
        weekdays: draft.weekdays,
        graceMinutes: draft.graceMinutes,
      ),
      history: const <MeasurementVersion>[],
    );
  }
}

void main() {
  setUpAll(initTestLocalization);

  /// The form for a new plan, opened over a home page so that leaving it
  /// has somewhere to go.
  Future<_Measurements> open(WidgetTester tester) async {
    final _Measurements repository = _Measurements();
    final MeasurementPlansCubit cubit = MeasurementPlansCubit(repository);
    addTearDown(cubit.close);
    await cubit.load('c-1');
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const Text('home')),
        GoRoute(
          path: '/form',
          builder: (context, state) =>
              BlocProvider<MeasurementPlansCubit>.value(
                value: cubit,
                child: const MeasurementPlanFormPage(circleId: 'c-1'),
              ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpArabic(tester, router: router);
    unawaited(router.push<bool>('/form'));
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('a target left empty is refused and nothing is sent', (
    tester,
  ) async {
    final _Measurements repository = await open(tester);

    await tester.tap(find.text('measurements.save'.tr()));
    await tester.pumpAndSettle();

    expect(
      find.text('measurements.invalid_glucose_target'.tr()),
      findsOneWidget,
    );
    expect(repository.created, isEmpty);
  });

  testWidgets('a new plan starts on the patient today and closes the form', (
    tester,
  ) async {
    final _Measurements repository = await open(tester);

    await tester.enterText(find.byType(TextField).at(0), '70');
    await tester.enterText(find.byType(TextField).at(1), '130');
    await tester.tap(find.text('measurements.save'.tr()));
    await tester.pumpAndSettle();

    final MeasurementPlanDraft draft = repository.created.single;
    expect(draft.kind, MeasurementKind.glucose);
    expect((draft.glucoseLow, draft.glucoseHigh), (70, 130));
    // Noon in Riyadh on 9 November, whatever zone the test machine is in.
    expect(draft.startsOn, DateTime(2026, 11, 9));
    expect(find.text('home'), findsOneWidget);
  });
}
