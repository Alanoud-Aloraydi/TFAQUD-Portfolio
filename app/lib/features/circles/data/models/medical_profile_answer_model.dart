import 'package:app/features/circles/data/models/medical_profile_json.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';

/// The answer of PATCH /api/v1/circles/{id}/medical-profile:
/// `{"medical_profile": {...}}`.
class MedicalProfileAnswerModel {
  const MedicalProfileAnswerModel(this._profile);

  final MedicalProfileDraft _profile;

  factory MedicalProfileAnswerModel.fromJson(Map<String, dynamic> json) {
    return MedicalProfileAnswerModel(
      MedicalProfileJson.fromJson(
        json['medical_profile'] as Map<String, dynamic>,
      ),
    );
  }

  MedicalProfileDraft toEntity() => _profile;
}
