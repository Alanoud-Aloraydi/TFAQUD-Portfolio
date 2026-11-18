import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_code_request.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_countdown.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_requesting.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_scope.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_typing.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_verifying.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates sign in actions and UI state.
class SignInCubit extends Cubit<SignInState>
    with
        SignInScope,
        SignInTyping,
        SignInCountdown,
        SignInCodeRequest,
        SignInRequesting,
        SignInVerifying {
  /// [clock] tells the time the resend wait is measured against; the tests
  /// give their own.
  SignInCubit(this.useCase, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now,
      super(const SignInState());

  @override
  final AuthUseCase useCase;

  @override
  final DateTime Function() clock;

  /// Digits in the code. The SMS template of Authentica sends six.
  static const int codeLength = 6;

  /// Seconds the user waits before asking for a new code when the server
  /// does not say (it normally does: 30 s, then longer after each code).
  static const int resendCooldownSeconds = 45;

  @override
  Future<void> close() {
    countdown?.cancel();
    return super.close();
  }
}
