import 'package:app/app/router/care_item_routes.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/features/appointments/domain/repositories/visit_audio.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/usecases/visits_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_page.dart';
import 'package:app/features/appointments/presentation/pages/visit_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// A circle's appointment: its form (new or edit) and its visit page.
List<RouteBase> appointmentRoutes() => <RouteBase>[
  GoRoute(
    path: CareItemRoutes.appointmentNewPath,
    pageBuilder: iosModalPage(
      (context, state) => _appointmentForm(state.pathParameters['circleId']!),
    ),
  ),
  GoRoute(
    path: CareItemRoutes.appointmentEditPath,
    pageBuilder: iosModalPage(
      (context, state) => _appointmentForm(
        state.pathParameters['circleId']!,
        appointmentId: state.pathParameters['appointmentId'],
      ),
    ),
  ),
  GoRoute(
    path: CareItemRoutes.appointmentVisitPath,
    pageBuilder: iosPage((context, state) {
      final circleId = state.pathParameters['circleId']!;
      final appointmentId = state.pathParameters['appointmentId']!;
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AppointmentsCubit(GetIt.I<AppointmentsUseCase>())
                  ..load(circleId),
          ),
          BlocProvider(
            create: (_) => VisitCubit(
              GetIt.I<VisitsUseCase>(),
              GetIt.I<VisitAudio>(),
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
];

/// The appointment form of [circleId]: a new appointment, or the one of
/// [appointmentId]. Its companions are the circle's members to choose from.
Widget _appointmentForm(String circleId, {String? appointmentId}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            AppointmentsCubit(GetIt.I<AppointmentsUseCase>())..load(circleId),
      ),
      BlocProvider(
        create: (_) =>
            AppointmentCompanionsCubit(GetIt.I<AppointmentsUseCase>())
              ..load(circleId),
      ),
    ],
    child: AppointmentFormPage(
      circleId: circleId,
      appointmentId: appointmentId,
    ),
  );
}
