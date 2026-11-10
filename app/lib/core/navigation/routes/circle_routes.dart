part of '../app_router.dart';

/// Creating a circle, the requests and invitations, and a circle's medical
/// file and emergency card.
List<RouteBase> _circleRoutes() => <RouteBase>[
  // A circle is created on one page with its own CreateCircleCubit. The
  // circle for the signed-in person's own care loads the account at the
  // start, to learn whether it already has a circle and holds the birth
  // date and city. Once created, the page `go`es to the circle tab, so
  // the creation pages leave the stack.
  // When the server says the sign-in ended, the page sends the user to
  // sign-in.
  _createCircleShell(
    flow: CircleFlow.self,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.createSelfCircle,
        pageBuilder: _iosPage(
          (context, state) => const SelfCircleBasicsScreen(),
        ),
      ),
    ],
  ),
  // The same for a patient who does not use the app. The names
  // of the patient are typed, so no account is loaded.
  _createCircleShell(
    flow: CircleFlow.patient,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.createPatientCircle,
        pageBuilder: _iosPage(
          (context, state) => const PatientCircleBasicsScreen(),
        ),
      ),
    ],
  ),
  // A request to a patient who uses the app: the phone number, then the
  // waiting state on the same page.
  GoRoute(
    path: Routes.requestPatient,
    pageBuilder: _iosPage(
      (context, state) => BlocProvider(
        create: (context) => SendCircleRequestCubit(GetIt.I<CirclesUseCase>()),
        child: const RequestPatientScreen(),
      ),
    ),
  ),
  // What waits for an answer: invitations and requests. The page of a
  // request takes the patient's answer; "agree" leads to the basic data.
  GoRoute(
    path: Routes.notifications,
    pageBuilder: _iosModalPage(
      (context, state) => BlocProvider(
        create: (context) =>
            InboxCubit(GetIt.I<CirclesUseCase>(), GetIt.I<HomeUseCase>())
              ..load(),
        child: const NotificationsScreen(),
      ),
    ),
  ),
  GoRoute(
    path: Routes.replyRequest,
    redirect: requireExtra<ReceivedCircleRequest>(Routes.notifications),
    pageBuilder: _iosPage(
      (context, state) => BlocProvider(
        create: (context) => RequestReplyCubit(
          GetIt.I<CirclesUseCase>(),
          state.extra! as ReceivedCircleRequest,
        ),
        child: const RequestReplyScreen(),
      ),
    ),
  ),
  // The page after the patient agreed: it creates the circle. The request
  // travels with the page.
  _createCircleShell(
    flow: CircleFlow.approved,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.completeRequest,
        redirect: requireExtra<ReceivedCircleRequest>(Routes.notifications),
        pageBuilder: _iosPage(
          (context, state) => const ApprovedCircleBasicsScreen(),
        ),
      ),
    ],
  ),
  // The medical file of a circle, its edit page and its emergency card.
  // Each page loads what it shows from the server for the circle in the
  // address.
  GoRoute(
    path: Routes.medicalFilePath,
    pageBuilder: _iosPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (context) =>
            MedicalFileCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
        child: MedicalFileScreen(circleId: circleId),
      );
    }),
  ),
  GoRoute(
    path: Routes.medicalFileEditPath,
    pageBuilder: _iosPage(
      (context, state) =>
          _medicalFileEdit(state, const MedicalFileEditScreen()),
    ),
  ),
  GoRoute(
    path: Routes.emergencyCardPath,
    pageBuilder: _iosPage(
      (context, state) =>
          _emergencyCard(state.pathParameters['circleId']!, Routes.circle),
    ),
  ),
];

/// The medical file's edit page [screen] with its cubit. It starts from
/// the file the medical file page passes (no second read); opened from its
/// address alone, it reads the file.
Widget _medicalFileEdit(GoRouterState state, Widget screen) {
  return BlocProvider(
    create: (context) {
      final MedicalFileEditCubit cubit = MedicalFileEditCubit(
        GetIt.I<CirclesUseCase>(),
        state.pathParameters['circleId']!,
      );
      final Object? file = state.extra;
      if (file is MedicalFile) {
        cubit.start(file);
      } else {
        cubit.load();
      }
      return cubit;
    },
    child: screen,
  );
}

/// The emergency card of [circleId], with the medicines it lists;
/// [closeTo] is where «رجوع» goes when there is no page under it.
Widget _emergencyCard(String circleId, String closeTo) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) =>
            EmergencyCardCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
      ),
      BlocProvider(
        create: (context) =>
            MedicationsCubit(GetIt.I<MedicationsUseCase>())..load(circleId),
      ),
    ],
    child: EmergencyCardScreen(closeTo: closeTo),
  );
}

/// The shell of a circle-creation [flow]: one [CreateCircleCubit] for its
/// [routes], and back to sign-in when the server says the sign-in ended.
ShellRoute _createCircleShell({
  required CircleFlow flow,
  required List<RouteBase> routes,
}) {
  return ShellRoute(
    pageBuilder: _iosShellPage(
      (context, state, child) => BlocProvider(
        create: (context) {
          final Object? extra = state.extra;
          // The request is the approved flow's `extra`; the route's
          // redirect sends a missing one back to the notifications.
          // The account says at once whether it already has a circle of
          // its own care; the patient flow loads none.
          return CreateCircleCubit(
            GetIt.I<CirclesUseCase>(),
            GetIt.I<HomeUseCase>(),
            flow: flow,
            request: extra is ReceivedCircleRequest ? extra : null,
          )..loadAccount();
        },
        child: BlocListener<CreateCircleCubit, CreateCircleState>(
          listenWhen: (before, after) =>
              after.sessionEnded && !before.sessionEnded,
          listener: (context, state) => context.go(Routes.auth),
          child: child,
        ),
      ),
    ),
    routes: routes,
  );
}
