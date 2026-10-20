import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._useCase) : super(AuthInitialState());

  final AuthUseCase _useCase;

  Future<void> signOut() async {
    if (state is AuthLoadingState) return; // a second tap does nothing
    emit(AuthLoadingState());
    await _useCase.signOut();
    if (isClosed) return;
    // The repository removes the tokens even when the server call fails, so
    // the user is signed out on this phone in both cases.
    emit(AuthSignedOutState());
  }
}
