import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/circles/data/models/account_model.dart';
import 'package:app/features/circles/data/models/circle_model.dart';
import 'package:app/features/circles/data/models/circle_request_model.dart';
import 'package:app/features/circles/data/models/complete_circle_request_model.dart';
import 'package:app/features/circles/data/models/medical_file_model.dart';
import 'package:app/features/circles/data/models/new_patient_circle_model.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:injectable/injectable.dart';

abstract class BaseCirclesRemoteDataSource {
  /// GET /api/v1/accounts/me.
  Future<AccountModel> getAccount();

  /// POST /api/v1/circles/self.
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body);

  /// POST /api/v1/circles/patient-without-account.
  Future<CircleModel> createPatientCircle(NewPatientCircleModel body);

  /// POST /api/v1/circle-requests.
  Future<SentCircleRequestModel> sendCircleRequest(NewCircleRequestModel body);

  /// GET /api/v1/circle-requests: the requests sent and the requests received.
  Future<CircleRequestsModel> getCircleRequests();

  /// GET /api/v1/invitations: invitations to manage a circle.
  Future<List<ReceivedInvitation>> getInvitations();

  /// POST /api/v1/circle-requests/{id}/respond.
  Future<SentCircleRequestModel> respondToRequest(
    String id, {
    required bool accept,
  });

  /// POST /api/v1/invitations/{id}/respond. Returns the id of the circle when
  /// the invitation was accepted, and null when it was declined.
  Future<String?> respondToInvitation(String id, {required bool accept});

  /// POST /api/v1/circle-requests/{id}/complete.
  Future<CircleModel> completeRequest(
    String id,
    CompleteCircleRequestModel body,
  );

  /// DELETE /api/v1/circle-requests/{id}.
  Future<void> cancelRequest(String id);

  /// DELETE /api/v1/accounts/me.
  Future<void> deleteAccount(AccountDeletion deletion);

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

@LazySingleton(as: BaseCirclesRemoteDataSource)
class CirclesRemoteDataSource implements BaseCirclesRemoteDataSource {
  CirclesRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<AccountModel> getAccount() async {
    final response = await _client.get(ApiEndpoints.account);
    return AccountModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body) async {
    final response = await _client.post(
      ApiEndpoints.selfCircle,
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleModel> createPatientCircle(NewPatientCircleModel body) async {
    final response = await _client.post(
      ApiEndpoints.patientCircle,
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SentCircleRequestModel> sendCircleRequest(
    NewCircleRequestModel body,
  ) async {
    final response = await _client.post(
      ApiEndpoints.circleRequests,
      data: body.toJson(),
    );
    return SentCircleRequestModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<CircleRequestsModel> getCircleRequests() async {
    final response = await _client.get(ApiEndpoints.circleRequests);
    return CircleRequestsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ReceivedInvitation>> getInvitations() async {
    final response = await _client.get(ApiEndpoints.invitations);
    return ReceivedInvitationsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<SentCircleRequestModel> respondToRequest(
    String id, {
    required bool accept,
  }) async {
    final response = await _client.post(
      ApiEndpoints.respondCircleRequest(id),
      data: <String, dynamic>{'accept': accept},
    );
    return SentCircleRequestModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<String?> respondToInvitation(String id, {required bool accept}) async {
    final response = await _client.post(
      ApiEndpoints.respondInvitation(id),
      data: <String, dynamic>{'accept': accept},
    );
    final Map<String, dynamic> body = response.data as Map<String, dynamic>;
    final Map<String, dynamic> invitation =
        body['invitation'] as Map<String, dynamic>;
    return invitation['care_circle_id'] as String?;
  }

  @override
  Future<CircleModel> completeRequest(
    String id,
    CompleteCircleRequestModel body,
  ) async {
    final response = await _client.post(
      ApiEndpoints.completeCircleRequest(id),
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> cancelRequest(String id) async {
    await _client.delete(ApiEndpoints.circleRequest(id));
  }

  @override
  Future<void> deleteAccount(AccountDeletion deletion) async {
    final PatientChoice? choice = deletion.patientChoice;
    final Map<String, dynamic> body = <String, dynamic>{
      if (choice != null)
        'patient_choice': choice == PatientChoice.delete ? 'delete' : 'continue',
      if (deletion.deleteLastManagedCircles) 'delete_last_managed_circles': true,
    };
    // An account with no circles sends no body.
    await _client.delete(
      ApiEndpoints.account,
      data: body.isEmpty ? null : body,
    );
  }

  @override
  Future<MedicalFile> getMedicalFile(String circleId) async {
    final response = await _client.get(ApiEndpoints.medicalProfile(circleId));
    return MedicalFileModel.fromJson(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<MedicalProfileDraft> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) async {
    final response = await _client.patch(
      ApiEndpoints.medicalProfile(circleId),
      data: MedicalProfileJson.toPatchJson(profile),
    );
    return MedicalProfileAnswerModel.fromJson(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<void> updatePatient(String circleId, PatientUpdate update) async {
    await _client.put(
      ApiEndpoints.circlePatient(circleId),
      data: PatientUpdateModel(update).toJson(),
    );
  }

  @override
  Future<EmergencyContact> addContact(
    String circleId,
    ContactDraft draft,
  ) async {
    final response = await _client.post(
      ApiEndpoints.emergencyContacts(circleId),
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
      ApiEndpoints.emergencyContact(circleId, contactId),
      data: EmergencyContactModel.draftToJson(draft),
    );
    return EmergencyContactModel.fromAnswer(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<void> deleteContact(String circleId, String contactId) async {
    await _client.delete(ApiEndpoints.emergencyContact(circleId, contactId));
  }

  @override
  Future<EmergencyCard> getEmergencyCard(String circleId) async {
    final response = await _client.get(ApiEndpoints.emergencyCard(circleId));
    return EmergencyCardModel.fromJson(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }
}
