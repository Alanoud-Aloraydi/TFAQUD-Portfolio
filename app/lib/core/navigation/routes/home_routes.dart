part of '../app_router.dart';

/// The detailed mode's home: four tabs (اليوم، الخطة، السجل، الدائرة) under
/// one shell that provides the cubits every tab shares.
StatefulShellRoute _homeShell() => StatefulShellRoute(
  // The tabs fade into each other instead of swapping at once.
  navigatorContainerBuilder: (context, navigationShell, children) =>
      FadingBranches(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
  // The home cubit loads the circles. The inbox cubit counts what waits
  // for an answer, for the dot on the bell; it loads again whenever the
  // circles change.
  pageBuilder: _iosShellRootPage(
    (context, state, navigationShell) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeCubit(
            GetIt.I<HomeUseCase>(),
            GetIt.I<PrivatePhotoRepository>().changes,
            GetIt.I<ShownCircleClock>(),
          )..load(),
        ),
        BlocProvider(
          create: (context) => InboxCubit(
            GetIt.I<CirclesUseCase>(),
            GetIt.I<HomeUseCase>(),
            followCircleChanges: true,
          )..load(),
        ),
        BlocProvider(
          create: (context) => MedicationsCubit(GetIt.I<MedicationsUseCase>()),
        ),
        BlocProvider(
          create: (context) => MedicationOccurrencesCubit(
            GetIt.I<MedicationsUseCase>(),
            photoChanges: GetIt.I<PrivatePhotoRepository>().changes,
          ),
        ),
        BlocProvider(
          create: (context) =>
              MeasurementPlansCubit(GetIt.I<MeasurementRepository>()),
        ),
        BlocProvider(
          create: (context) => MeasurementTasksCubit(
            GetIt.I<MeasurementRepository>(),
            GetIt.I<PrivatePhotoRepository>().changes,
          ),
        ),
        BlocProvider(
          create: (context) => MeasurementReadingsCubit(
            GetIt.I<MeasurementRepository>(),
            GetIt.I<PrivatePhotoRepository>().changes,
          ),
        ),
        BlocProvider(
          create: (context) =>
              AppointmentsCubit(GetIt.I<AppointmentRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              PrayerTimesCubit(GetIt.I<PrayerTimesRepository>()),
        ),
      ],
      child: HomeFeatureScreen(navigationShell: navigationShell),
    ),
  ),
  branches: <StatefulShellBranch>[
    _branch(Routes.today, builder: (context, state) => const TodayPage()),
    _branch(Routes.plan, builder: (context, state) => const PlanPage()),
    _branch(Routes.record, builder: (context, state) => const RecordPage()),
    // The circle tab shows the selected circle with the buttons of its
    // medical file and its emergency card.
    _branch(
      Routes.circle,
      builder: (context, state) => const CircleTabScreen(),
    ),
  ],
);

/// One home tab at [path], drawn by [builder] (an empty page without one).
StatefulShellBranch _branch(String path, {GoRouterWidgetBuilder? builder}) {
  final GoRouterWidgetBuilder page =
      builder ?? (context, state) => const SizedBox.expand();
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: path,
        // A tab page is the first page of its own navigator and has no
        // background of its own: the shell's canvas shows through it. An
        // iOS page (CupertinoPage) draws a light shadow (9% black) under
        // itself, which over a see-through page darkened the whole tab and
        // left a lighter band under the top bar. A tab page never slides
        // in (tabs fade, FadingBranches), so it is a plain page.
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          name: state.name ?? state.path,
          restorationId: state.pageKey.value,
          child: page(context, state),
        ),
      ),
    ],
  );
}
