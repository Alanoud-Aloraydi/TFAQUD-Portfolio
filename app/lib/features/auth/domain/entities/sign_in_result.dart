import 'package:equatable/equatable.dart';

/// What the app learns after a correct code. The session itself (the tokens)
/// is saved by the repository and is not part of this result.
class SignInResult extends Equatable {
  const SignInResult({required this.needsProfile, this.appMode});

  /// True when the user has not saved the name page yet: a new account, or an
  /// earlier sign-in that stopped before the names were saved. The app then
  /// shows the name page; otherwise it goes to the home page.
  final bool needsProfile;
  final String? appMode;

  @override
  List<Object?> get props => [needsProfile, appMode];
}
