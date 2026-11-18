import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_scope.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Saving the name step.
mixin OnboardingSaving on Cubit<OnboardingState>, OnboardingScope {
  /// Saves the names, birth date and city in one request.
  ///
  /// Returns true when they were saved, so the page can move on. An
  /// incomplete form only turns its errors on; a second tap while saving is
  /// ignored; a failure keeps the answers and shows its message key, and
  /// an ended sign-in sets [OnboardingState.sessionEnded] instead.
  Future<bool> saveProfile() async {
    if (state.status == OnboardingStatus.saving) return false;
    if (!state.isProfileValid) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    emit(state.copyWith(status: OnboardingStatus.saving, clearError: true));
    final result = await profile.saveProfile(
      firstName: state.firstName.trim(),
      lastName: state.lastName.trim(),
      displayName: state.displayName.trim(),
      birthDate: state.birthDate!,
      city: state.city!,
    );
    if (isClosed) return false;
    return result.when(
      (_) {
        emit(state.copyWith(status: OnboardingStatus.idle));
        return true;
      },
      (Failure failure) {
        final bool ended =
            failure is UnauthorizedFailure || failure is SessionExpiredFailure;
        emit(
          state.copyWith(
            status: OnboardingStatus.idle,
            errorKey: ended ? null : failure.messageKey,
            sessionEnded: ended,
          ),
        );
        return false;
      },
    );
  }
}
