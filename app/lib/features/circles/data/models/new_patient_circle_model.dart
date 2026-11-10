import 'package:app/core/utils/api_date.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';

/// The body of POST /api/v1/circles/patient-without-account
/// (docs/api-contracts.md): the two names of the patient, the birth date,
/// the city and the patient's IANA zone ([timeZone]). No name: the server
/// names the circle.
class NewPatientCircleModel {
  const NewPatientCircleModel(this._circle, [this._timeZone]);

  final NewPatientCircle _circle;
  final String? _timeZone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'patient_first_name': _circle.patientFirstName,
    'patient_last_name': _circle.patientLastName,
    'birth_date': apiDate(_circle.birthDate),
    'city': _circle.city,
    'time_zone': ?_timeZone,
  };
}
