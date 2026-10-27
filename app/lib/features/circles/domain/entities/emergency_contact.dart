import 'package:equatable/equatable.dart';

/// One person to call in an emergency, as the medical file and the emergency
/// card show it (docs/api-contracts.md, "The medical file").
class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phoneNumber,
  });

  final String id;
  final String name;

  /// One of [MedicalOptions.contactRelations]: `son`, `daughter`, `husband`,
  /// `wife` or `other`.
  final String relation;

  /// With the country code, `+9665XXXXXXXX`.
  final String phoneNumber;

  /// The first letter of the name, for the round picture of the row.
  String get initial {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? '' : String.fromCharCode(trimmed.runes.first);
  }

  /// The number without the country code, `5XXXXXXXX`, as the phone field
  /// holds it.
  String get nationalNumber => phoneNumber.startsWith('+966')
      ? phoneNumber.substring('+966'.length)
      : phoneNumber;

  @override
  List<Object?> get props => [id, name, relation, phoneNumber];
}

/// What the user typed for a contact: the same three fields for a new contact
/// and for a change of an old one.
class ContactDraft extends Equatable {
  const ContactDraft({
    required this.name,
    required this.relation,
    required this.phoneNumber,
  });

  /// 1 to 50 characters, already trimmed.
  final String name;
  final String relation;

  /// With the country code, `+9665XXXXXXXX`.
  final String phoneNumber;

  @override
  List<Object?> get props => [name, relation, phoneNumber];
}
