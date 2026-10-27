import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';

/// The body of POST /api/v1/circles/patient-without-account
/// (docs/api-contracts.md): the body of the self circle, plus the two names of
/// the patient.
class NewPatientCircleModel {
  const NewPatientCircleModel(this._circle);

  final NewPatientCircle _circle;

  Map<String, dynamic> toJson() {
    final MedicalProfileDraft? medical = _circle.medicalProfile;
    return <String, dynamic>{
      'name': _circle.name,
      'patient_first_name': _circle.patientFirstName,
      'patient_last_name': _circle.patientLastName,
      'birth_date': NewSelfCircleModel.isoDate(_circle.birthDate),
      'city': _circle.city,
      if (medical != null && !medical.isEmpty)
        'medical_profile': NewSelfCircleModel.medicalJson(medical),
    };
  }
}
