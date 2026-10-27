import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';

/// The body of POST /api/v1/circle-requests/{id}/complete
/// (docs/api-contracts.md): the birth date, the city and, when the patient
/// answered, the medical profile.
class CompleteCircleRequestModel {
  const CompleteCircleRequestModel(this._request);

  final CompleteCircleRequest _request;

  Map<String, dynamic> toJson() {
    final MedicalProfileDraft? medical = _request.medicalProfile;
    return <String, dynamic>{
      'birth_date': NewSelfCircleModel.isoDate(_request.birthDate),
      'city': _request.city,
      if (medical != null && !medical.isEmpty)
        'medical_profile': NewSelfCircleModel.medicalJson(medical),
    };
  }
}
