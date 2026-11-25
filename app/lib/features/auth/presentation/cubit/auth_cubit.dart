import 'package:app/core/errors/storage_failures.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:equatable/equatable.dart';
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

/// Nothing was asked yet.
class AuthInitialState extends AuthState {}

/// The tokens are gone from this phone. The screen goes to the welcome page.
class AuthSignedOutState extends AuthState {
  const AuthSignedOutState({this.serverConfirmed = true});

  /// False when the server could not be reached: the person is out of this
  /// phone, and the page says the server may still hold the session.
  final bool serverConfirmed;

  @override
  List<Object?> get props => [serverConfirmed];
}

/// The tokens could not be removed from this phone.
class AuthErrorState extends AuthState {
  const AuthErrorState({required this.messageKey});

  /// A key in assets/translations, never a text from the server.
  final String messageKey;

  @override
  List<Object?> get props => [messageKey];
}

/// State of the sign-out row.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The sign-out is running.
class AuthLoadingState extends AuthState {}
