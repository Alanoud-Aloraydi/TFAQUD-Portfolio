import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where the app goes after it starts. [checking] is the state while it finds
/// out; [unavailable] means the server could not be asked (the tokens are
/// kept and the page offers a retry).
enum StartDestination {
  checking,
  home,
  simplifiedHome,
  signIn,
  onboarding,
  unavailable,
}

/// Decides whether the app opens on the home page, the name page or the
/// sign-in page. The answer comes from the tokens on this phone and from the
/// server. [decide] runs again for the retry.
class SplashCubit extends Cubit<StartDestination> {
  SplashCubit(this._useCase) : super(StartDestination.checking);

  final AuthUseCase _useCase;
  int _run = 0;

  /// Asks the use case and emits the destination. When it is called again
  /// while an earlier call waits, only the latest answer is used.
  Future<void> decide() async {
    final int run = ++_run;
    emit(StartDestination.checking);
    final result = await _useCase.restoreSession();
    if (isClosed || run != _run) return;
    emit(
      result.when(
        (SignInResult? account) => switch (account) {
          null => StartDestination.signIn,
          SignInResult(needsProfile: true) => StartDestination.onboarding,
          SignInResult(appMode: CircleAppMode.simplified) =>
            StartDestination.simplifiedHome,
          _ => StartDestination.home,
        },
        (_) => StartDestination.unavailable,
      ),
    );
  }
}
