import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';

/// The body of POST /api/v1/circles/self (docs/api-contracts.md).
class NewSelfCircleModel {
  const NewSelfCircleModel(this._circle);

  final NewSelfCircle _circle;

  Map<String, dynamic> toJson() {
    final MedicalProfileDraft? medical = _circle.medicalProfile;
    final DateTime? birthDate = _circle.birthDate;
    final String? city = _circle.city;
    return <String, dynamic>{
      'name': _circle.name,
      // Left out: the server reads them from the account.
      if (birthDate != null) 'birth_date': isoDate(birthDate),
      'city': ?city,
      if (medical != null && !medical.isEmpty)
        'medical_profile': medicalJson(medical),
    };
  }

  /// `YYYY-MM-DD`, written by hand so that no locale can change the digits.
  static String isoDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Only the parts the user answered. A part that is left out stays unknown.
  static Map<String, dynamic> medicalJson(MedicalProfileDraft medical) {
    final ConditionsDraft? conditions = medical.conditions;
    final AllergiesDraft? allergies = medical.allergies;
    return <String, dynamic>{
      if (medical.bloodType != null) 'blood_type': medical.bloodType,
      if (conditions != null)
        'conditions': <String, dynamic>{
          'status': conditions.answer.name,
          'codes': conditions.codes,
          'other': conditions.other,
        },
      if (allergies != null)
        'allergies': <String, dynamic>{
          'status': allergies.answer.name,
          'medication': allergies.medication,
          'other_medication': allergies.otherMedication,
          'food': allergies.food,
          'other_food': allergies.otherFood,
        },
    };
  }
}
