import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/core/navigation/routes/require_extra.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/pages/notifications_screen.dart';
import 'package:app/features/circles/presentation/pages/request_reply_screen.dart';
import 'package:app/features/circles/presentation/pages/request_patient_screen.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
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
