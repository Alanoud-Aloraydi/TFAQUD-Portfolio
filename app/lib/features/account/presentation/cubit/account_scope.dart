import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What every part of the account cubit works on: the use cases it asks, the
/// counter that drops an older reading, and how a failure ends the session.
mixin AccountScope on Cubit<AccountState> {
  CirclesUseCase get circles;
  ProfileUseCase get profile;
  AuthUseCase get auth;
  HomeUseCase get home;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// Whether the failure means the sign-in is no longer valid.
  bool endsSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
