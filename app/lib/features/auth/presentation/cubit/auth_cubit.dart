import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._useCase) : super(AuthInitialState());

  final AuthUseCase _useCase;

  Future<void> signOut() async {
    if (state is AuthLoadingState) return; // a second tap does nothing
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
