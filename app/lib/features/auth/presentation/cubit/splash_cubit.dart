import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where the app goes after it starts. [checking] is the state while it finds out.
enum StartDestination { checking, home, signIn, onboarding, unavailable }

/// Decides, once, whether the app opens on the home page or on the sign-in
/// page. The answer comes from the tokens on this phone and from the server.
class SplashCubit extends Cubit<StartDestination> {
  SplashCubit(this._useCase) : super(StartDestination.checking);

  final AuthUseCase _useCase;

  Future<void> decide() async {
    emit(StartDestination.checking);
    final result = await _useCase.restoreSession();
    if (isClosed) return;
    emit(
      result.when(
        (account) => switch (account?.needsProfile) {
          null => StartDestination.signIn,
          true => StartDestination.onboarding,
          false => StartDestination.home,
        },
        (_) => StartDestination.unavailable,
      ),
    );
  }
}
