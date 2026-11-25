import 'package:app/features/circles/data/models/medical_profile_json.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';

/// One contact of the API: `{id, name, relation, relation_other,
/// phone_number, verified, account}`.
class EmergencyContactModel {
  const EmergencyContactModel(this._entity);

  final EmergencyContact _entity;

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      EmergencyContact(
        id: json['id'] as String,
        name: json['name'] as String,
        relation: json['relation'] as String,
        relationOther: json['relation_other'] as String?,
        phoneNumber: json['phone_number'] as String,
        verified: json['verified'] as bool? ?? false,
        accountId:
            (json['account'] as Map<String, dynamic>?)?['account_id']
                as String?,
        avatarCode:
            (json['account'] as Map<String, dynamic>?)?['avatar_code']
                as String?,
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
      // Only with «أخرى»; the server refuses the words without it.
      if (draft.relationOther != null) 'relation_other': draft.relationOther,
      'phone_number': draft.phoneNumber,
    };
  }
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
        contacts: emergencyContactsOf(card['emergency_contacts']),
      ),
    );
  }

  EmergencyCard toEntity() => _entity;
}

/// The emergency contacts of an answer, in the order the server sent them;
/// none when the answer carries none.
List<EmergencyContact> emergencyContactsOf(Object? value) {
  return <EmergencyContact>[
    for (final Object? item in (value as List<dynamic>? ?? <dynamic>[]))
      EmergencyContactModel.fromJson(item as Map<String, dynamic>).toEntity(),
  ];
}
