import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/require_extra.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/pages/notifications_screen.dart';
import 'package:app/features/circles/presentation/pages/request_patient_screen.dart';
import 'package:app/features/circles/presentation/pages/request_reply_screen.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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
