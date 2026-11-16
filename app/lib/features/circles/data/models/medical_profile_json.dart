import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';

/// Reads and writes the health answers in the shape of the API
/// (docs/api-contracts.md, "The medical file").
abstract class MedicalProfileJson {
  MedicalProfileJson._();

  /// Reads the `medical_profile` object. A status of `unknown` gives a null
  /// part, which is how the app writes "nobody answered yet".
  static MedicalProfileDraft fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? conditions =
        json['conditions'] as Map<String, dynamic>?;
    final Map<String, dynamic>? allergies =
        json['allergies'] as Map<String, dynamic>?;
    return MedicalProfileDraft(
      bloodType: json['blood_type'] as String?,
      conditions: conditions == null ? null : _conditions(conditions),
      allergies: allergies == null ? null : _allergies(allergies),
    );
  }

  static ConditionsDraft? _conditions(Map<String, dynamic> json) {
    switch (json['status']) {
      case 'none':
        return const ConditionsDraft.none();
      case 'listed':
        return ConditionsDraft.listed(
          codes: _strings(json['codes']),
          other: json['other'] as String?,
        );
      default:
        return null;
    }
  }

  static AllergiesDraft? _allergies(Map<String, dynamic> json) {
    switch (json['status']) {
      case 'none':
        return const AllergiesDraft.none();
      case 'listed':
        return AllergiesDraft.listed(
          medication: _strings(json['medication']),
          otherMedication: json['other_medication'] as String?,
          food: _strings(json['food']),
          otherFood: json['other_food'] as String?,
        );
      default:
        return null;
    }
  }

  static List<String> _strings(Object? value) {
    return <String>[
      for (final Object? item in (value as List<dynamic>? ?? <dynamic>[]))
        item as String,
    ];
  }

  /// The body of PATCH /api/v1/circles/{id}/medical-profile. Every part is
  /// sent: a part with no answer is sent as `null`, which clears it back to
  /// "unknown" on the server.
  static Map<String, dynamic> toPatchJson(MedicalProfileDraft profile) {
    final ConditionsDraft? conditions = profile.conditions;
    final AllergiesDraft? allergies = profile.allergies;
    return <String, dynamic>{
      'blood_type': profile.bloodType,
      'conditions': conditions == null
          ? null
          : <String, dynamic>{
              'status': conditions.answer.name,
              'codes': conditions.codes,
              'other': conditions.other,
            },
      'allergies': allergies == null
          ? null
          : <String, dynamic>{
              'status': allergies.answer.name,
              'medication': allergies.medication,
              'other_medication': allergies.otherMedication,
              'food': allergies.food,
              'other_food': allergies.otherFood,
            },
    };
  }
}
