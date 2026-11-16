part of '../circles_remote_data_source.dart';

/// The medical file, the emergency contacts and the emergency card.
abstract interface class CircleMedicalApi {
  /// GET /api/v1/circles/{id}/medical-profile: the whole medical file page.
  Future<MedicalFile> getMedicalFile(String circleId);

  /// PATCH /api/v1/circles/{id}/medical-profile. Returns the saved answers.
  Future<MedicalProfileDraft> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  );

  /// PUT /api/v1/circles/{id}/patient.
  Future<void> updatePatient(String circleId, PatientUpdate update);

  /// POST /api/v1/circles/{id}/emergency-contacts.
  Future<EmergencyContact> addContact(String circleId, ContactDraft draft);

  /// PUT /api/v1/circles/{id}/emergency-contacts/{contactId}.
  Future<EmergencyContact> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  );

  /// DELETE /api/v1/circles/{id}/emergency-contacts/{contactId}.
  Future<void> deleteContact(String circleId, String contactId);

  /// GET /api/v1/circles/{id}/emergency-card.
  Future<EmergencyCard> getEmergencyCard(String circleId);
}
