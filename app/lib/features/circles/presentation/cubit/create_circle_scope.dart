import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The longest typed circle name. The API accepts 60; a short name is what
/// fits in the row of circles at the top of the screen.
const int maxCustomNameLength = 30;

/// What the page that creates a circle is working with: which circle is
/// being created, and the request behind it when a patient agreed to one.
mixin CreateCircleScope on Cubit<CreateCircleState> {
  CirclesUseCase get circles;
  HomeUseCase get home;

  /// Which circle is created: the signed-in person's own, one for a patient
  /// without the app, or the one a patient agreed to.
  CircleFlow get flow;

  /// The request of the [CircleFlow.approved] flow.
  ReceivedCircleRequest? get request;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
