import 'package:app/app/router/medical_file_paths.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/require_extra.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/utils/shown_circle_clock.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/routing/circle_care_pages.dart';
import 'package:app/features/home/routing/loaded_account_cubit.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_account_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_name_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_measure_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_medical_file_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_reminder_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_schedule_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_skip_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_focus.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile.dart';
import 'package:flutter/widgets.dart';
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
      GoRoute(
        path: Routes.simplifiedAccountName,
        pageBuilder: iosPage(
          (context, state) => BlocProvider(
            create: (context) => loadedAccountCubit(),
            child: const SimplifiedNameScreen(),
          ),
        ),
      ),
      ...simplifiedCareRoutes(),
    ],
  );
}

/// The simplified mode's screens about one task: its reminder, snoozing or
/// skipping it, and the word after it is done. The task travels as the
/// navigation's `extra`; without it the phone goes back to the home.
List<RouteBase> simplifiedTaskRoutes() => <RouteBase>[
  GoRoute(
    path: Routes.simplifiedReminder,
    redirect: requireExtra<ReminderRequest>(Routes.simplifiedMode),
    pageBuilder: iosModalPage(
      (context, state) =>
          SimplifiedReminderScreen(request: state.extra! as ReminderRequest),
    ),
  ),
  GoRoute(
    path: Routes.simplifiedSnooze,
    redirect: requireExtra<TodayTask>(Routes.simplifiedMode),
    pageBuilder: iosPage(
      (context, state) =>
          SimplifiedSnoozeScreen(task: state.extra! as TodayTask),
    ),
  ),
  GoRoute(
    path: Routes.simplifiedSkip,
    redirect: requireExtra<TodayTask>(Routes.simplifiedMode),
    pageBuilder: iosPage(
      (context, state) => SimplifiedSkipScreen(task: state.extra! as TodayTask),
    ),
  ),
  GoRoute(
    path: Routes.simplifiedDone,
    redirect: requireExtra<SimplifiedDoneMessage>(Routes.simplifiedMode),
    pageBuilder: iosPage(
      (context, state) =>
          SimplifiedDoneScreen(message: state.extra! as SimplifiedDoneMessage),
    ),
  ),
];

/// A circle's emergency card and medical file inside the simplified shell.
List<RouteBase> simplifiedCareRoutes() => <RouteBase>[
  // The same card as the detailed mode's, but inside this shell and at
  // this mode's size, like the edit page below it: «رجوع» never lands
  // in the detailed mode.
  GoRoute(
    path: MedicalFilePaths.simplifiedEmergencyCardPath,
    pageBuilder: iosPage(
      (context, state) => SimplifiedDetailScale(
        child: emergencyCardPage(
          state.pathParameters['circleId']!,
          Routes.simplifiedMode,
        ),
      ),
    ),
  ),
  GoRoute(
    path: MedicalFilePaths.simplifiedMedicalFilePath,
    pageBuilder: iosPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (context) =>
            MedicalFileCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
        child: SimplifiedMedicalFileScreen(circleId: circleId),
      );
    }),
  ),
  // The detailed mode's edit page inside this shell, at this mode's
  // size: «حفظ» and «رجوع» return to the simplified medical file.
  GoRoute(
    path: MedicalFilePaths.simplifiedMedicalFileEditPath,
    pageBuilder: iosPage(
      (context, state) => medicalFileEditPage(
        state,
        SimplifiedDetailScale(
          child: MedicalFileEditScreen(
            savedTo: null,
            closeTo: Routes.simplifiedMedicalFile(
              state.pathParameters['circleId']!,
            ),
          ),
        ),
      ),
    ),
  ),
];

/// The one day ([SimplifiedModeCubit]) and the one text size every
/// simplified screen shares, above [child].
Widget simplifiedShellCubits({required Widget child}) => MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => SimplifiedModeCubit(
        GetIt.I<SimplifiedModeUseCase>(),
        photoChanges: GetIt.I<PrivatePhotoRepository>().changes,
        shownClock: GetIt.I<ShownCircleClock>(),
      )..load(),
    ),
    BlocProvider(
      create: (context) =>
          SimplifiedSettingsCubit(GetIt.I<SimplifiedSettingsStore>())..load(),
    ),
  ],
  child: SimplifiedTextScale(child: child),
);
