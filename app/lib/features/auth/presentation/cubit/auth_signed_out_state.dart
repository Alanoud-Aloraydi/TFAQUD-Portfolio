import 'package:app/features/auth/presentation/cubit/auth_state.dart';

/// The tokens are gone from this phone. The screen goes to the welcome page.
class AuthSignedOutState extends AuthState {
  const AuthSignedOutState({this.serverConfirmed = true});

  /// False when the server could not be reached: the person is out of this
  /// phone, and the page says the server may still hold the session.
  final bool serverConfirmed;

  @override
  List<Object?> get props => [serverConfirmed];
}
