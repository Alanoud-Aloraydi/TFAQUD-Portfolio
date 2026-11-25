import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/require_extra.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/circle_member_actions.dart';
import 'package:app/features/circles/presentation/pages/approved_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/patient_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/self_circle_basics_screen.dart';
import 'package:app/features/circles/routing/circle_request_routes.dart';
import 'package:app/features/circles/routing/medical_file_routes.dart';
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
