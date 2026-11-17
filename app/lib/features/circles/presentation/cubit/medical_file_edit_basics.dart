import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The patient's basic data as it is typed: the names, the birth date, the
/// city and its zone.
mixin MedicalFileEditBasics
    on Cubit<MedicalFileEditState>, MedicalFileEditScope {
  void firstNameChanged(String value) =>
      emit(state.copyWith(firstName: value, clearError: true));

  void lastNameChanged(String value) =>
      emit(state.copyWith(lastName: value, clearError: true));

  void birthDateChanged(DateTime value) =>
      emit(state.copyWith(birthDate: value, clearError: true));

  /// A city of the Saudi list brings its zone; a city typed by hand leaves
  /// the zone empty, to be picked ([timeZoneChanged]). Keeping the old
  /// zone would read every plan and reminder on the wrong clock.
  void cityChanged(String value) {
    final String? zone = SaudiCities.zoneOf(value);
    emit(
      state.copyWith(
        city: value,
        timeZone: zone,
        clearTimeZone: zone == null,
        clearError: true,
      ),
    );
  }

  /// The IANA zone where the patient lives, picked by hand.
  void timeZoneChanged(String value) =>
      emit(state.copyWith(timeZone: value, clearError: true));
}
