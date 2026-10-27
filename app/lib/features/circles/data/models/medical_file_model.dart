import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';

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

/// One contact of the API: `{id, name, relation, phone_number}`.
class EmergencyContactModel {
  const EmergencyContactModel(this._entity);

  final EmergencyContact _entity;

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      EmergencyContact(
        id: json['id'] as String,
        name: json['name'] as String,
        relation: json['relation'] as String,
        phoneNumber: json['phone_number'] as String,
      ),
    );
  }

  /// Reads the answer of a call that adds or changes a contact:
  /// `{"emergency_contact": {...}}`.
  factory EmergencyContactModel.fromAnswer(Map<String, dynamic> json) {
    return EmergencyContactModel.fromJson(
      json['emergency_contact'] as Map<String, dynamic>,
    );
  }

  EmergencyContact toEntity() => _entity;

  /// The body of POST and PUT on the contacts.
  static Map<String, dynamic> draftToJson(ContactDraft draft) {
    return <String, dynamic>{
      'name': draft.name,
      'relation': draft.relation,
      'phone_number': draft.phoneNumber,
    };
  }
}

List<EmergencyContact> _contacts(Object? value) {
  return <EmergencyContact>[
    for (final Object? item in (value as List<dynamic>? ?? <dynamic>[]))
      EmergencyContactModel.fromJson(item as Map<String, dynamic>).toEntity(),
  ];
}

/// The answer of GET /api/v1/circles/{id}/medical-profile.
class MedicalFileModel {
  const MedicalFileModel(this._entity);

  final MedicalFile _entity;

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> patient =
        json['patient'] as Map<String, dynamic>;
    return MedicalFileModel(
      MedicalFile(
        patient: PatientBasics(
          firstName: patient['first_name'] as String? ?? '',
          lastName: patient['last_name'] as String? ?? '',
          birthDate: parseDate(patient['birth_date'] as String),
          city: patient['city'] as String? ?? '',
          hasAccount: patient['has_account'] as bool? ?? false,
          latitude: (patient['latitude'] as num?)?.toDouble(),
          longitude: (patient['longitude'] as num?)?.toDouble(),
        ),
        profile: MedicalProfileJson.fromJson(
          json['medical_profile'] as Map<String, dynamic>,
        ),
        contacts: _contacts(json['emergency_contacts']),
      ),
    );
  }

  MedicalFile toEntity() => _entity;

  /// `YYYY-MM-DD` to a date without a time zone. The date is built from its
  /// parts, so no time zone can move it to another day.
  static DateTime parseDate(String iso) {
    final List<String> parts = iso.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

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

/// The answer of GET /api/v1/circles/{id}/emergency-card.
class EmergencyCardModel {
  const EmergencyCardModel(this._entity);

  final EmergencyCard _entity;

  factory EmergencyCardModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> card =
        json['emergency_card'] as Map<String, dynamic>;
    return EmergencyCardModel(
      EmergencyCard(
        firstName: card['first_name'] as String? ?? '',
        lastName: card['last_name'] as String? ?? '',
        profile: MedicalProfileJson.fromJson(card),
        contacts: _contacts(card['emergency_contacts']),
      ),
    );
  }

  EmergencyCard toEntity() => _entity;
}

/// The body of PUT /api/v1/circles/{id}/patient.
class PatientUpdateModel {
  const PatientUpdateModel(this._update);

  final PatientUpdate _update;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'birth_date': NewSelfCircleModel.isoDate(_update.birthDate),
      'city': _update.city,
      'first_name': ?_update.firstName,
      'last_name': ?_update.lastName,
      'latitude': _update.latitude,
      'longitude': _update.longitude,
    };
  }
}
