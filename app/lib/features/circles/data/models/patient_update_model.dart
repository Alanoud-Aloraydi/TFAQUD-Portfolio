import 'package:app/core/utils/api_date.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';

/// The body of PUT /api/v1/circles/{id}/patient.
class PatientUpdateModel {
  const PatientUpdateModel(this._update);

  final PatientUpdate _update;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'birth_date': apiDate(_update.birthDate),
      'city': _update.city,
      'first_name': ?_update.firstName,
      'last_name': ?_update.lastName,
      'latitude': _update.latitude,
      'longitude': _update.longitude,
      'time_zone': ?_update.timeZone,
    };
  }
}
