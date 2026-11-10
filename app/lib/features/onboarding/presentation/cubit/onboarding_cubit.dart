import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Presentation logic of the first account set-up (onboarding).
///
/// Flow: `ProfileStepScreen` and `StartScreen` → this cubit →
/// [ProfileUseCase] → PUT /api/v1/accounts/me/profile → the `account`
/// table. One instance lives in the onboarding `ShellRoute`, so the name
/// step and the start step share the typed answers and the choice.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._profile) : super(const OnboardingState());

  final ProfileUseCase _profile;

  /// Keeps the typed first name and clears any shown server error.
  void firstNameChanged(String value) {
    emit(state.copyWith(firstName: value, clearError: true));
  }

  /// Keeps the typed last name and clears any shown server error.
  void lastNameChanged(String value) {
    emit(state.copyWith(lastName: value, clearError: true));
  }

  /// Keeps the display name and clears any shown server error.
  void displayNameChanged(String value) {
    emit(state.copyWith(displayName: value, clearError: true));
  }

  /// Keeps the picked birth date and clears any shown server error.
  void birthDateChanged(DateTime value) {
    emit(state.copyWith(birthDate: value, clearError: true));
  }

  /// Keeps the picked city and clears any shown server error.
  void cityChanged(String value) {
    emit(state.copyWith(city: value, clearError: true));
  }

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
    final result = await _profile.saveProfile(
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

  /// Picks who the care is for. Choosing [CareTarget.self] clears the
  /// follow-up question, which belongs to "another person" only.
  void selectCareTarget(CareTarget target) {
    emit(
      state.copyWith(
        careTarget: target,
        clearPatientUsesApp: target == CareTarget.self,
      ),
    );
  }

  /// Answers whether the cared-for person uses the app.
  void selectPatientUsesApp({required bool usesApp}) {
    emit(state.copyWith(patientUsesApp: usesApp));
  }
}
