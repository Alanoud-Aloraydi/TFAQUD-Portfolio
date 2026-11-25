import 'dart:async';

import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan_draft.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_filling.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../support/normal_ranges.dart';
import '../support/widget_harness.dart';

/// No plans yet; remembers the plans the form saves.
class _Measurements extends Fake implements MeasurementsRepository {
  final List<MeasurementPlanDraft> created = <MeasurementPlanDraft>[];

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<MeasurementPlan>> plans(String circleId) async =>
      const <MeasurementPlan>[];

  @override
  Future<NormalRanges> ranges(String circleId) async => generalRanges();

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
        missedAfterMinutes: draft.missedAfterMinutes,
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
    // The form reads the normal ranges itself.
    GetIt.I.registerSingleton<MeasurementsRepository>(repository);
    addTearDown(() => GetIt.I.unregister<MeasurementsRepository>());
    final MeasurementPlansCubit cubit = MeasurementPlansCubit(
      MeasurementsUseCase(repository),
    );
    addTearDown(cubit.close);
    await cubit.load('c-1');
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
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

  testWidgets('shows the fixed normal range, with nothing to type', (
    tester,
  ) async {
    await open(tester);
    // The ranges sit at the end of the form, past the first screen: a
    // long drag lands there, and the list builds them.
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    // The default glucose time is fasting: the fasting range only.
    expect(find.text('measurements.normal_range'.tr()), findsWidgets);
    expect(find.textContaining('70–100'), findsWidgets);
    expect(find.textContaining('70–140'), findsNothing);
    expect(find.text('measurements.change_condition'.tr()), findsOneWidget);
  });

  testWidgets('a new plan starts on the patient today and closes the form', (
    tester,
  ) async {
    final _Measurements repository = await open(tester);

    await tester.tap(find.text('measurements.save'.tr()));
    await tester.pumpAndSettle();

    final MeasurementPlanDraft draft = repository.created.single;
    expect(draft.kind, MeasurementKind.glucose);
    expect(draft.toJson().containsKey('glucose_low'), isFalse);
    // Noon in Riyadh on 9 November, whatever zone the test machine is in.
    expect(draft.startsOn, DateTime(2026, 11, 9));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the missed-after minutes are chosen on the ruler, 5 to 360, '
      'and sent as chosen', (tester) async {
    final _Measurements repository = await open(tester);

    await tester.ensureVisible(find.byType(MissedAfterField));
    await tester.tap(find.byType(MissedAfterField));
    await tester.pumpAndSettle();
    final RulerPicker ruler = tester.widget(find.byType(RulerPicker));
    expect((ruler.min, ruler.max), (5, 360));
    ruler.onChanged(45);
    await tester.pump();
    await tester.tap(find.text('common.confirm'.tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('measurements.save'.tr()));
    await tester.pumpAndSettle();

    expect(repository.created.single.missedAfterMinutes, 45);
  });

  testWidgets('saving a plan says so', (tester) async {
    await open(tester);

    await tester.tap(find.text('measurements.save'.tr()));
    await tester.pumpAndSettle();

    expect(find.text('toast.measurement_plan_saved'.tr()), findsOneWidget);
  });
}
