part of '../circles_remote_data_source.dart';

/// The calls for the medical file, the contacts and the emergency card.
mixin _MedicalRequests implements CircleMedicalApi {
  DioClient get _client;

  @override
  Future<MedicalFile> getMedicalFile(String circleId) async {
    final response = await _client.get(
      CircleEndpoints.medicalProfile(circleId),
    );
    return MedicalFileModel.fromJson(response.data as Map<String, dynamic>)
        .toEntity();
  }

  @override
  Future<MedicalProfileDraft> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) async {
    final response = await _client.patch(
      CircleEndpoints.medicalProfile(circleId),
      data: MedicalProfileJson.toPatchJson(profile),
    );
    return MedicalProfileAnswerModel.fromJson(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<void> updatePatient(String circleId, PatientUpdate update) async {
    await _client.put(
      CircleEndpoints.circlePatient(circleId),
      data: PatientUpdateModel(update).toJson(),
    );
  }

  @override
  Future<EmergencyContact> addContact(
    String circleId,
    ContactDraft draft,
  ) async {
    final response = await _client.post(
      CircleEndpoints.emergencyContacts(circleId),
      data: EmergencyContactModel.draftToJson(draft),
    );
    return EmergencyContactModel.fromAnswer(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<EmergencyContact> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) async {
    final response = await _client.put(
      CircleEndpoints.emergencyContact(circleId, contactId),
      data: EmergencyContactModel.draftToJson(draft),
    );
    return EmergencyContactModel.fromAnswer(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<void> deleteContact(String circleId, String contactId) async {
    await _client.delete(CircleEndpoints.emergencyContact(circleId, contactId));
  }

  @override
  Future<EmergencyCard> getEmergencyCard(String circleId) async {
    final response = await _client.get(CircleEndpoints.emergencyCard(circleId));
    return EmergencyCardModel.fromJson(response.data as Map<String, dynamic>)
        .toEntity();
  }
}
