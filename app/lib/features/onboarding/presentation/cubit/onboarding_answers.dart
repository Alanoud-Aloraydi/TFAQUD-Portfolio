import 'package:app/features/onboarding/presentation/cubit/onboarding_scope.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the person types or picks on the name step.
mixin OnboardingAnswers on Cubit<OnboardingState>, OnboardingScope {
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
}
