import 'package:app/features/circles/data/models/emergency_contacts_of.dart';
import 'package:app/features/circles/data/models/medical_profile_json.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';

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
