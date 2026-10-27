import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

/// The basic data of the patient on the medical file page: GET
/// /api/v1/circles/{id}/medical-profile, part `patient`.
class PatientBasics extends Equatable {
  const PatientBasics({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.city,
    required this.hasAccount,
    this.latitude,
    this.longitude,
  });

  /// While the patient has an account the names are the account's names, and
  /// only the patient can change them (on the account page).
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String city;

  /// True when the patient uses the app. A patient without an account has the
  /// names typed by the managers, so the managers can edit them.
  final bool hasAccount;

  final double? latitude;
  final double? longitude;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    birthDate,
    city,
    hasAccount,
    latitude,
    longitude,
  ];
}

/// The whole medical file page: the patient, the health answers and the
/// emergency contacts.
///
/// [profile] is a [MedicalProfileDraft] whose parts are null while the answer
/// is "unknown" (nobody has answered yet). "None" is a real answer and is not
/// null.
class MedicalFile extends Equatable {
  MedicalFile({
    required this.patient,
    required this.profile,
    required List<EmergencyContact> contacts,
  }) : contacts = List.unmodifiable(contacts);

  /// The server keeps at most this many contacts for a patient.
  static const int maxContacts = 5;

  final PatientBasics patient;
  final MedicalProfileDraft profile;
  final List<EmergencyContact> contacts;

  bool get canAddContact => contacts.length < maxContacts;

  MedicalFile copyWith({
    PatientBasics? patient,
    MedicalProfileDraft? profile,
    List<EmergencyContact>? contacts,
  }) {
    return MedicalFile(
      patient: patient ?? this.patient,
      profile: profile ?? this.profile,
      contacts: contacts ?? this.contacts,
    );
  }

  @override
  List<Object?> get props => [patient, profile, contacts];
}
