import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._useCase) : super(const OnboardingState());

  final OnboardingUseCase _useCase;

  void firstNameChanged(String value) {
    emit(state.copyWith(firstName: value, clearError: true));
  }

  void lastNameChanged(String value) {
    emit(state.copyWith(lastName: value, clearError: true));
  }

  void displayNameChanged(String value) {
    emit(state.copyWith(displayName: value, clearError: true));
  }

  /// Saves the name. Returns true when it was saved, so the page can move on.
  Future<bool> saveProfile() async {
    if (state.status == OnboardingStatus.saving) return false;
    if (!state.isProfileValid) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    emit(state.copyWith(status: OnboardingStatus.saving, clearError: true));
    final result = await _useCase.saveProfile(
      firstName: state.firstName.trim(),
      lastName: state.lastName.trim(),
      displayName: state.displayName.trim(),
    );
    if (isClosed) return false;
    return result.when(
      (saved) {
        emit(state.copyWith(status: OnboardingStatus.saved));
        return true;
      },
      (failure) {
        emit(
          state.copyWith(
            status: OnboardingStatus.idle,
            errorKey: failure.messageKey,
          ),
        );
        return false;
      },
    );
  }

  void selectCareTarget(CareTarget target) {
    // The second question belongs to "another person" only.
    emit(
      state.copyWith(
        careTarget: target,
        clearPatientUsesApp: target == CareTarget.self,
      ),
    );
  }

  void selectPatientUsesApp({required bool usesApp}) {
    emit(state.copyWith(patientUsesApp: usesApp));
  }
}
