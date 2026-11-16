import 'package:app/features/circles/presentation/cubit/create_circle_scope.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/cubit/name_preset.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the person answers on the page. Every answer clears the message of
/// the try before it, so what is shown belongs to what is on screen now.
mixin CreateCircleAnswers on Cubit<CreateCircleState>, CreateCircleScope {
  void choosePreset(NamePreset preset) {
    emit(state.copyWith(namePreset: preset, clearError: true));
  }

  void customNameChanged(String value) {
    emit(state.copyWith(customName: value, clearError: true));
  }

  void birthDateChanged(DateTime value) {
    emit(state.copyWith(birthDate: value, clearError: true));
  }

  void cityChanged(String value) {
    emit(state.copyWith(city: value, clearError: true));
  }

  void patientFirstNameChanged(String value) {
    emit(state.copyWith(patientFirstName: value, clearError: true));
  }

  void patientLastNameChanged(String value) {
    emit(state.copyWith(patientLastName: value, clearError: true));
  }
}
