import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';

/// What makes two [SignInState]s equal: every field, in the order the
/// class declares them.
List<Object?> signInStateProps(SignInState state) => <Object?>[
  state.phone,
  state.code,
  state.status,
  state.errorKey,
  state.showPhoneError,
  state.resendSeconds,
  state.verificationId,
  state.needsProfile,
  state.appMode,
];
