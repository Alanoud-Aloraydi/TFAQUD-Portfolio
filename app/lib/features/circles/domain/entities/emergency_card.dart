import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

/// The read-only emergency card: GET /api/v1/circles/{id}/emergency-card.
/// It carries only what a helper needs: the name, the blood type, the
/// allergies, the chronic conditions and the people to call. The current
/// medicines are added when the medication feature exists.
class EmergencyCard extends Equatable {
  EmergencyCard({
    required this.firstName,
    required this.lastName,
    required this.profile,
    required List<EmergencyContact> contacts,
  }) : contacts = List.unmodifiable(contacts);

  final String firstName;
  final String lastName;

  /// Parts that nobody answered are null.
  final MedicalProfileDraft profile;
  final List<EmergencyContact> contacts;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [firstName, lastName, profile, contacts];
}
