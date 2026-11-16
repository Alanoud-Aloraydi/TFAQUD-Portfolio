import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the inbox is read with, shared by everything it does.
mixin InboxScope on Cubit<InboxState> {
  CirclesUseCase get circles;
  HomeUseCase get home;

  /// Counts the readings, so a slower one cannot overwrite a newer answer.
  int revision = 0;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
