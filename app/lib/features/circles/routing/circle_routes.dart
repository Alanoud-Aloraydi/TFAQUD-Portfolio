import 'package:app/app/router/medical_file_paths.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/require_extra.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_screen.dart';
import 'package:app/features/circles/presentation/pages/notifications_screen.dart';
import 'package:app/features/circles/presentation/pages/patient_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/request_patient_screen.dart';
import 'package:app/features/circles/presentation/pages/request_reply_screen.dart';
import 'package:app/features/circles/routing/circle_care_pages.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Creating a circle, the requests and invitations, and a circle's medical
/// file and emergency card.
List<RouteBase> circleRoutes() => <RouteBase>[
  // A circle is created on one page with its own CreateCircleCubit. The
  // circle for the signed-in person's own care loads the account at the
  // start, to learn whether it already has a circle and holds the birth
  // date and city. Once created, the page `go`es to the circle tab, so
  // the creation pages leave the stack.
  // When the server says the sign-in ended, the page sends the user to
  // sign-in.
  createCircleShell(
    flow: CircleFlow.self,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.createSelfCircle,
        pageBuilder: iosPage(
          (context, state) => const SelfCircleBasicsScreen(),
        ),
      ),
    ],
  ),
  // The same for a patient who does not use the app. The names
  // of the patient are typed, so no account is loaded.
  createCircleShell(
    flow: CircleFlow.patient,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.createPatientCircle,
        pageBuilder: iosPage(
          (context, state) => const PatientCircleBasicsScreen(),
        ),
      ),
    ],
  ),
  ...circleRequestRoutes(),
  // The page after the patient agreed: it creates the circle. The request
  // travels with the page.
  createCircleShell(
    flow: CircleFlow.approved,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.completeRequest,
        redirect: requireExtra<ReceivedCircleRequest>(Routes.notifications),
        pageBuilder: iosPage(
          (context, state) => const ApprovedCircleBasicsScreen(),
        ),
      ),
    ],
  ),
  ...medicalFileRoutes(),
];

/// The medical file of a circle, its edit page and its emergency card.
/// Each page loads what it shows from the server for the circle in the
/// address.
List<RouteBase> medicalFileRoutes() => <RouteBase>[
  GoRoute(
    path: MedicalFilePaths.medicalFilePath,
    pageBuilder: iosPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (context) =>
            MedicalFileCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
        child: MedicalFileScreen(circleId: circleId),
      );
    }),
  ),
  GoRoute(
    path: MedicalFilePaths.medicalFileEditPath,
    pageBuilder: iosPage(
      (context, state) =>
          medicalFileEditPage(state, const MedicalFileEditScreen()),
    ),
  ),
  GoRoute(
    path: MedicalFilePaths.emergencyCardPath,
    pageBuilder: iosPage(
      (context, state) =>
          emergencyCardPage(state.pathParameters['circleId']!, Routes.circle),
    ),
  ),
];

/// A request to a patient, and what waits for an answer.
List<RouteBase> circleRequestRoutes() => <RouteBase>[
  // A request to a patient who uses the app: the phone number, then the
  // waiting state on the same page.
  GoRoute(
    path: Routes.requestPatient,
    pageBuilder: iosPage(
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
    pageBuilder: iosModalPage(
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
    pageBuilder: iosPage(
      (context, state) => BlocProvider(
        create: (context) => RequestReplyCubit(
          GetIt.I<CirclesUseCase>(),
          state.extra! as ReceivedCircleRequest,
        ),
        child: const RequestReplyScreen(),
      ),
    ),
  ),
];

/// The shell of a circle-creation [flow]: one [CreateCircleCubit] for its
/// [routes], and back to sign-in when the server says the sign-in ended.
ShellRoute createCircleShell({
  required CircleFlow flow,
  required List<RouteBase> routes,
}) {
  return ShellRoute(
    pageBuilder: iosShellPage(
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
