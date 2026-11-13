part of '../app_router.dart';

/// The pages of a circle's medicines, measurements and appointments, opened
/// from the home tabs. Each one loads what it shows for the circle in the
/// address.
List<RouteBase> _careRoutes() => <RouteBase>[
  GoRoute(
    path: Routes.medicationNewPath,
    pageBuilder: _iosModalPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (context) =>
            MedicationsCubit(GetIt.I<MedicationsUseCase>())..bind(circleId),
        child: MedicationFormPage(circleId: circleId),
      );
    }),
  ),
  GoRoute(
    path: Routes.measurementNewPath,
    pageBuilder: _iosModalPage((context, state) {
      final circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (_) =>
            MeasurementPlansCubit(GetIt.I<MeasurementRepository>())
              ..load(circleId),
        child: MeasurementPlanFormPage(circleId: circleId),
      );
    }),
  ),
  GoRoute(
    path: Routes.measurementEditPath,
    pageBuilder: _iosModalPage((context, state) {
      final circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (_) =>
            MeasurementPlansCubit(GetIt.I<MeasurementRepository>())
              ..load(circleId),
        child: MeasurementPlanFormPage(
          circleId: circleId,
          planId: state.pathParameters['planId']!,
        ),
      );
    }),
  ),
  GoRoute(
    path: Routes.appointmentNewPath,
    pageBuilder: _iosModalPage(
      (context, state) => _appointmentForm(state.pathParameters['circleId']!),
    ),
  ),
  GoRoute(
    path: Routes.appointmentEditPath,
    pageBuilder: _iosModalPage(
      (context, state) => _appointmentForm(
        state.pathParameters['circleId']!,
        appointmentId: state.pathParameters['appointmentId'],
      ),
    ),
  ),
  GoRoute(
    path: Routes.appointmentVisitPath,
    pageBuilder: _iosPage((context, state) {
      final circleId = state.pathParameters['circleId']!;
      final appointmentId = state.pathParameters['appointmentId']!;
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AppointmentsCubit(GetIt.I<AppointmentRepository>())
                  ..load(circleId),
          ),
          BlocProvider(
            create: (_) => VisitCubit(
              GetIt.I<VisitRepository>(),
              VisitAudioService(),
              circleId,
              appointmentId,
            )..load(),
          ),
        ],
        child: VisitPage(
          appointmentId: appointmentId,
          canManage: state.extra == true,
        ),
      );
    }),
  ),
  GoRoute(
    path: Routes.medicationDetailsPath,
    pageBuilder: _iosPage((context, state) {
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
    path: Routes.medicationEditPath,
    pageBuilder: _iosModalPage((context, state) {
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

/// The appointment form of [circleId]: a new appointment, or the one of
/// [appointmentId]. Its companions are the circle's members to choose from.
Widget _appointmentForm(String circleId, {String? appointmentId}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            AppointmentsCubit(GetIt.I<AppointmentRepository>())..load(circleId),
      ),
      BlocProvider(
        create: (_) =>
            AppointmentCompanionsCubit(GetIt.I<AppointmentRepository>())
              ..load(circleId),
      ),
    ],
    child: AppointmentFormPage(
      circleId: circleId,
      appointmentId: appointmentId,
    ),
  );
}
