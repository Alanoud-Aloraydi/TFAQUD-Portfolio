import 'package:app/core/utils/saudi_mobile.dart';
import 'package:equatable/equatable.dart';

/// One person to call in an emergency, as the medical file and the emergency
/// card show it (docs/api-contracts.md, "The medical file").
class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phoneNumber,
    this.relationOther,
    this.verified = false,
    this.accountId,
    this.avatarCode,
  });

  final String id;
  final String name;

  /// One of [MedicalOptions.contactRelations]: `son`, `daughter`, `husband`,
  /// `wife` or `other`.
  final String relation;

  /// The relation in the user's words when [relation] is `other`.
  final String? relationOther;

  /// With the country code, `+9665XXXXXXXX`.
  final String phoneNumber;

  /// «متحقق»: the number is a TFAQUD account's, so the person uses the app.
  final bool verified;

  /// The account of a contact who is in the circle, and their avatar, for
  /// their picture; null for anyone else.
  final String? accountId;
  final String? avatarCode;

  /// The first letter of the name, for the round picture of the row.
  String get initial {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? '' : String.fromCharCode(trimmed.runes.first);
  }

  /// The number without the country code, `5XXXXXXXX`, as the phone field
  /// holds it.
  String get nationalNumber => SaudiMobile.national(phoneNumber);

  @override
  List<Object?> get props => [
    id,
    name,
    relation,
    relationOther,
    phoneNumber,
    verified,
    accountId,
    avatarCode,
  ];
}

/// What the user typed for a contact: the same fields for a new contact and
/// for a change of an old one.
class ContactDraft extends Equatable {
  const ContactDraft({
    required this.name,
    required this.relation,
    required this.phoneNumber,
    this.relationOther,
  });

  /// 1 to 50 characters, already trimmed.
  final String name;
  final String relation;

  /// Trimmed, exactly when [relation] is `other`.
  final String? relationOther;

  /// With the country code, `+9665XXXXXXXX`.
  final String phoneNumber;

  @override
  List<Object?> get props => [name, relation, relationOther, phoneNumber];
}

/// The ambulance number the emergency card calls. It is Saudi Arabia's
/// (997): the app does not store the patient's country, and a per-country
/// number is a product decision left open (see the notes' decisions). This
/// is the only place the number is written.
abstract final class EmergencyNumber {
  static const String ambulance = '997';
}
