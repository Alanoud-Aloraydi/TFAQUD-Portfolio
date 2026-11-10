import 'package:equatable/equatable.dart';

/// State of the sign-out row.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Nothing was asked yet.
class AuthInitialState extends AuthState {}

/// The sign-out is running.
class AuthLoadingState extends AuthState {}

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
