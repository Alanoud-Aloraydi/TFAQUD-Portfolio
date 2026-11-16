import 'package:app/features/circles/domain/entities/emergency_contact.dart';

/// One contact of the API: `{id, name, relation, phone_number, verified,
/// account}`.
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
      'phone_number': draft.phoneNumber,
    };
  }
}
