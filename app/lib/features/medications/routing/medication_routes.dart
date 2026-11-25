import 'package:app/app/router/care_item_routes.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_filling.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/pages/medication_details_page.dart';
import 'package:app/features/medications/presentation/pages/medication_form_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The form that adds a medicine to the circle in the address. It comes
/// before [medicationPlanRoutes], whose plan id would otherwise take «new».
GoRoute medicationNewRoute() => GoRoute(
  path: CareItemRoutes.medicationNewPath,
  pageBuilder: iosModalPage((context, state) {
    final String circleId = state.pathParameters['circleId']!;
    return BlocProvider(
      create: (context) =>
          MedicationsCubit(GetIt.I<MedicationsUseCase>())..bind(circleId),
      child: MedicationFormPage(circleId: circleId),
    );
  }),
);

/// One medicine of a circle: its details page and its edit form.
List<RouteBase> medicationPlanRoutes() => <RouteBase>[
  GoRoute(
    path: CareItemRoutes.medicationDetailsPath,
    pageBuilder: iosPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      final String planId = state.pathParameters['planId']!;
      return BlocProvider(
        create: (context) =>
            MedicationsCubit(GetIt.I<MedicationsUseCase>())
              ..loadPlan(circleId, planId),
        child: MedicationDetailsPage(
          circleId: circleId,
          planId: planId,
          // Every way in passes whether the viewer manages the circle's
          // medicines; without it (a typed or restored address) the page
          // is read-only, and the server still checks every change.
          canManage: state.extra == true,
        ),
      );
    }),
  ),
  GoRoute(
    path: CareItemRoutes.medicationEditPath,
    pageBuilder: iosModalPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      final String planId = state.pathParameters['planId']!;
      return BlocProvider(
        create: (context) =>
            MedicationsCubit(GetIt.I<MedicationsUseCase>())
              ..loadPlan(circleId, planId),
        child: MedicationFormPage(circleId: circleId, planId: planId),
      );
    }),
  ),
];

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
