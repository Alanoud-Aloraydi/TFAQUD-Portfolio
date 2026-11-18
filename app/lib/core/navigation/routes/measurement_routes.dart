import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/care_item_routes.dart';

/// The form of a circle's measurement plan: a new plan, or the one in the
/// address.
List<RouteBase> measurementRoutes() => <RouteBase>[
  GoRoute(
    path: CareItemRoutes.measurementNewPath,
    pageBuilder: iosModalPage((context, state) {
      final circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (_) =>
            MeasurementPlansCubit(GetIt.I<MeasurementsUseCase>())
              ..load(circleId),
        child: MeasurementPlanFormPage(circleId: circleId),
      );
    }),
  ),
  GoRoute(
    path: CareItemRoutes.measurementEditPath,
    pageBuilder: iosModalPage((context, state) {
      final circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (_) =>
            MeasurementPlansCubit(GetIt.I<MeasurementsUseCase>())
              ..load(circleId),
        child: MeasurementPlanFormPage(
          circleId: circleId,
          planId: state.pathParameters['planId']!,
        ),
      );
    }),
  ),
];
