import 'package:app/app/router/fading_branches.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/utils/shown_circle_clock.dart';
import 'package:app/core/widgets/layout/pull_to_refresh.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/pages/circle_tab_screen.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/pages/plan_page.dart';
import 'package:app/features/home/presentation/pages/today_page.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/prayer_times/domain/usecases/prayer_times_use_case.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The detailed mode's home: four tabs (اليوم، الخطة، السجل، الدائرة) under
/// one shell that provides the cubits every tab shares.
StatefulShellRoute homeShell() => StatefulShellRoute(
  // The tabs fade into each other instead of swapping at once.
  navigatorContainerBuilder: (context, navigationShell, children) =>
      FadingBranches(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
  pageBuilder: iosShellRootPage(
    (context, state, navigationShell) => homeShellCubits(
      child: HomeFeatureScreen(navigationShell: navigationShell),
    ),
  ),
  branches: <StatefulShellBranch>[
    homeTabBranch(Routes.today, builder: (context, state) => const TodayPage()),
    homeTabBranch(Routes.plan, builder: (context, state) => const PlanPage()),
    homeTabBranch(
      Routes.record,
      builder: (context, state) => const RecordPage(),
    ),
    // The circle tab shows the selected circle with the buttons of its
    // medical file and its emergency card.
    homeTabBranch(
      Routes.circle,
      builder: (context, state) => const CircleTabScreen(),
    ),
  ],
);

/// One home tab at [path], drawn by [builder] (an empty page without one).
StatefulShellBranch homeTabBranch(
  String path, {
  GoRouterWidgetBuilder? builder,
}) {
  final GoRouterWidgetBuilder page =
      builder ?? (context, state) => const SizedBox.expand();
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: path,
        // A tab page is the first page of its own navigator, see-through
        // to the shell's canvas: an iOS page (CupertinoPage) draws a 9%
        // shadow under itself that darkened the whole tab. A tab never
        // slides in (tabs fade), so it is a plain page; pulled down from
        // its top, it reads everything again.
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          name: state.name ?? state.path,
          restorationId: state.pageKey.value,
          child: PullToRefresh(child: page(context, state)),
        ),
      ),
    ],
  );
}

/// The cubits every home tab shares, above [child]. The home cubit loads
/// the circles. The inbox cubit counts what waits for an answer, for the
/// dot on the bell; it loads again whenever the circles change.
Widget homeShellCubits({required Widget child}) => MultiBlocProvider(
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
          MeasurementPlansCubit(GetIt.I<MeasurementsUseCase>()),
    ),
    BlocProvider(
      create: (context) => MeasurementTasksCubit(
        GetIt.I<MeasurementsUseCase>(),
        GetIt.I<PrivatePhotoRepository>().changes,
      ),
    ),
    BlocProvider(
      create: (context) => MeasurementReadingsCubit(
        GetIt.I<MeasurementsUseCase>(),
        GetIt.I<PrivatePhotoRepository>().changes,
      ),
    ),
    BlocProvider(
      create: (context) => AppointmentsCubit(GetIt.I<AppointmentsUseCase>()),
    ),
    BlocProvider(
      create: (context) => PrayerTimesCubit(GetIt.I<PrayerTimesUseCase>()),
    ),
  ],
  child: child,
);
