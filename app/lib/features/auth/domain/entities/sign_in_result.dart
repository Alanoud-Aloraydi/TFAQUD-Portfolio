import 'package:equatable/equatable.dart';

/// What the server tells the app after a correct code.
class SignInResult extends Equatable {
  const SignInResult({required this.isNewUser});

  /// True when this phone number had no account, so the server created one.
  /// The app then asks for the name; otherwise it goes to the home page.
  final bool isNewUser;

  @override
  List<Object?> get props => [isNewUser];
}
