import 'package:app/features/auth/presentation/cubit/auth_state.dart';

/// The tokens could not be removed from this phone.
class AuthErrorState extends AuthState {
  const AuthErrorState({required this.messageKey});

  /// A key in assets/translations, never a text from the server.
  final String messageKey;

  @override
  List<Object?> get props => [messageKey];
}
