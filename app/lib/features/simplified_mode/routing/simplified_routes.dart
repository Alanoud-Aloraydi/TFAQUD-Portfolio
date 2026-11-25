import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/home/routing/loaded_account_cubit.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_account_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_measure_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_mode_feature_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_schedule_screen.dart';
import 'package:app/features/simplified_mode/routing/simplified_care_routes.dart';
import 'package:app/features/simplified_mode/routing/simplified_task_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The simplified mode's screens share one day ([SimplifiedModeCubit]),
/// so a reminder, the day's list and the home always agree, and one text
/// size. The medical file's edit page and the emergency card are the
/// detailed mode's pages, routed inside this shell so the size holds and
/// leaving them returns here, never to the detailed mode.
ShellRoute simplifiedShell() {
  return ShellRoute(
    pageBuilder: iosShellPage(
      (context, state, child) => simplifiedShellCubits(child: child),
    ),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.simplifiedMode,
        pageBuilder: iosPage(
          (context, state) => const SimplifiedModeFeatureScreen(),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedSchedule,
        pageBuilder: iosPage(
          (context, state) => const SimplifiedScheduleScreen(),
        ),
      ),
      ...simplifiedTaskRoutes(),
      GoRoute(
        path: Routes.simplifiedMeasurePath,
        pageBuilder: iosPage(
          (context, state) => BlocProvider(
            create: (context) => SimplifiedMeasurementCubit(
              GetIt.I<SimplifiedModeUseCase>(),
              state.pathParameters['circleId']!,
              task: state.extra is MeasurementOccurrence
                  ? state.extra! as MeasurementOccurrence
                  : null,
            )..load(),
            child: const SimplifiedMeasureScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedAccount,
        pageBuilder: iosPage(
          (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => loadedAccountCubit()),
              BlocProvider(
                create: (context) => AuthCubit(GetIt.I<AuthUseCase>()),
              ),
            ],
            child: const SimplifiedAccountScreen(),
          ),
        ),
      ),
      ...simplifiedCareRoutes(),
    ],
  );
}
