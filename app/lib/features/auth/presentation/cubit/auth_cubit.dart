import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signs the person out. The page listens for [AuthSignedOutState] and goes
/// to the welcome page.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._useCase) : super(AuthInitialState());

  final AuthUseCase _useCase;

  /// Ends the session on the server and removes the tokens from this phone.
  /// A second tap while it runs does nothing. A [StorageFailure] (the tokens
  /// could not be removed) is an [AuthErrorState], so the person stays
  /// signed in and can try again; any other failure still signs out here.
  Future<void> signOut() async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    final result = await _useCase.signOut();
    if (isClosed) return;
    emit(
      result.when(
        (_) => const AuthSignedOutState(),
        (failure) => failure is StorageFailure
            ? AuthErrorState(messageKey: failure.messageKey)
            : const AuthSignedOutState(serverConfirmed: false),
      ),
    );
  }
}
