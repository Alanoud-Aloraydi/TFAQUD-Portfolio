import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

/// The tokens are gone from this phone. The screen goes to the welcome page.
class AuthSignedOutState extends AuthState {
  const AuthSignedOutState({this.serverConfirmed = true});

  final bool serverConfirmed;

  @override
  List<Object?> get props => [serverConfirmed];
}

class AuthErrorState extends AuthState {
  const AuthErrorState({required this.messageKey});

  /// A key in assets/translations, never a text from the server.
  final String messageKey;

  @override
  List<Object?> get props => [messageKey];
}
