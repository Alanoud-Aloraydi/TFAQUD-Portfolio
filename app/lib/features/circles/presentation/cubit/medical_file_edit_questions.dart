import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';

/// What the edit page asks about the patient's names and zone.
extension MedicalFileEditQuestions on MedicalFileEditState {
  /// The names are typed by the managers: the patient has no account.
  bool get namesEditable => file != null && !file!.patient.hasAccount;

  bool get namesComplete =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  /// The «المنطقة الزمنية» row shows for every city outside the Saudi
  /// list: a listed city brings Saudi Arabia's zone ([SaudiCities.zoneOf]),
  /// any other city needs the zone said out loud, because every reminder,
  /// plan and reading of the circle is read on it.
  bool get zoneEditable => city != null && SaudiCities.zoneOf(city) == null;

  /// Whether the zone is still missing for a city that needs one.
  bool get zoneMissing => zoneEditable && timeZone == null;
}
