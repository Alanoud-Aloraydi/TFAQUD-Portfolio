part of '../app_router.dart';

/// The simplified mode's screens share one day ([SimplifiedModeCubit]),
/// so a reminder, the day's list and the home always agree, and one text
/// size. The medical file's edit page and the emergency card are the
/// detailed mode's pages, routed inside this shell so the size holds and
/// leaving them returns here, never to the detailed mode.
ShellRoute _simplifiedShell() {
  return ShellRoute(
    pageBuilder: _iosShellPage(
      (context, state, child) => MultiBlocProvider(
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
                SimplifiedSettingsCubit(GetIt.I<SimplifiedPreferences>())
                  ..load(),
          ),
        ],
        child: SimplifiedTextScale(child: child),
      ),
    ),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.simplifiedMode,
        pageBuilder: _iosPage(
          (context, state) => const SimplifiedModeFeatureScreen(),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedSchedule,
        pageBuilder: _iosPage(
          (context, state) => const SimplifiedScheduleScreen(),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedReminder,
        redirect: requireExtra<ReminderRequest>(Routes.simplifiedMode),
        pageBuilder: _iosModalPage(
          (context, state) => SimplifiedReminderScreen(
            request: state.extra! as ReminderRequest,
          ),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedSnooze,
        redirect: requireExtra<TodayTask>(Routes.simplifiedMode),
        pageBuilder: _iosPage(
          (context, state) =>
              SimplifiedSnoozeScreen(task: state.extra! as TodayTask),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedDone,
        redirect: requireExtra<SimplifiedDoneMessage>(Routes.simplifiedMode),
        pageBuilder: _iosPage(
          (context, state) => SimplifiedDoneScreen(
            message: state.extra! as SimplifiedDoneMessage,
          ),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedMeasurePath,
        pageBuilder: _iosPage(
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
        pageBuilder: _iosPage(
          (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => _loadedAccountCubit()),
              BlocProvider(
                create: (context) => AuthCubit(GetIt.I<AuthUseCase>()),
              ),
            ],
            child: const SimplifiedAccountScreen(),
          ),
        ),
      ),
      // The same card as the detailed mode's, but inside this shell: the
      // text size holds, and «رجوع» never lands in the detailed mode.
      GoRoute(
        path: Routes.simplifiedEmergencyCardPath,
        pageBuilder: _iosPage(
          (context, state) => _emergencyCard(
            state.pathParameters['circleId']!,
            Routes.simplifiedMode,
          ),
        ),
      ),
      GoRoute(
        path: Routes.simplifiedMedicalFilePath,
        pageBuilder: _iosPage((context, state) {
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
        path: Routes.simplifiedMedicalFileEditPath,
        pageBuilder: _iosPage(
          (context, state) => _medicalFileEdit(
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
    ],
  );
}
