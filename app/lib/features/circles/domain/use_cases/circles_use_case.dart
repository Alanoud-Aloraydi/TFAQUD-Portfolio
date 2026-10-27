import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class CirclesUseCase {
  CirclesUseCase(this._repository);

  final CirclesRepositoryDomain _repository;

  Future<Result<AccountSummary, Failure>> getAccount() =>
      _repository.getAccount();

  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) => _repository.createSelfCircle(circle);

  Future<Result<CareCircleSummary, Failure>> createPatientCircle(
    NewPatientCircle circle,
  ) => _repository.createPatientCircle(circle);

  Future<Result<SentCircleRequest, Failure>> sendCircleRequest(
    NewCircleRequest request,
  ) => _repository.sendCircleRequest(request);

  Future<Result<CircleInbox, Failure>> getInbox() => _repository.getInbox();

  Future<Result<CircleRequestStatus, Failure>> respondToRequest(
    String id, {
    required bool accept,
  }) => _repository.respondToRequest(id, accept: accept);

  Future<Result<String?, Failure>> respondToInvitation(
    String id, {
    required bool accept,
  }) => _repository.respondToInvitation(id, accept: accept);

  Future<Result<CareCircleSummary, Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  ) => _repository.completeRequest(id, request);

  Future<Result<void, Failure>> cancelRequest(String id) =>
      _repository.cancelRequest(id);

  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion) =>
      _repository.deleteAccount(deletion);

  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId) =>
      _repository.getMedicalFile(circleId);

  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) => _repository.updateMedicalProfile(circleId, profile);

  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  ) => _repository.updatePatient(circleId, update);

  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  ) => _repository.addContact(circleId, draft);

  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) => _repository.updateContact(circleId, contactId, draft);

  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  ) => _repository.deleteContact(circleId, contactId);

  Future<Result<EmergencyCard, Failure>> getEmergencyCard(String circleId) =>
      _repository.getEmergencyCard(circleId);
}
