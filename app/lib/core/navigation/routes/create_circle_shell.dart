import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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
