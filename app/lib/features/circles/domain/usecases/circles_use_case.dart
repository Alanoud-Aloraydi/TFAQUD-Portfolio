import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/repositories/circles_repository.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

/// The circle reads and writes the application is allowed to make.
class CirclesUseCase with CirclesUseCaseScope {
  CirclesUseCase(this.repository);

  @override
  final CirclesRepository repository;

  Future<Result<CircleOverview, Failure>> getCircleOverview(String circleId) =>
      repository.getCircleOverview(circleId);

  Future<Result<void, Failure>> renameCircle(String circleId, String name) =>
      repository.renameCircle(circleId, name);

  Future<Result<void, Failure>> inviteManager(
    String circleId,
    String phoneNumber,
  ) => repository.inviteManager(circleId, phoneNumber);

  Future<Result<void, Failure>> resendManagerInvitation(
    String circleId,
    String invitationId,
  ) => repository.resendManagerInvitation(circleId, invitationId);

  Future<Result<void, Failure>> cancelManagerInvitation(
    String circleId,
    String invitationId,
  ) => repository.cancelManagerInvitation(circleId, invitationId);

  Future<Result<void, Failure>> setMemberEditAccess(
    String circleId,
    String accountId, {
    required String area,
    required bool allowed,
  }) => repository.setMemberEditAccess(
    circleId,
    accountId,
    area: area,
    allowed: allowed,
  );

  Future<Result<void, Failure>> handOverLeadership(
    String circleId,
    String accountId,
  ) => repository.handOverLeadership(circleId, accountId);

  Future<Result<void, Failure>> removeMember(
    String circleId,
    String accountId,
  ) => repository.removeMember(circleId, accountId);

  Future<Result<void, Failure>> leaveCircle(
    String circleId, {
    required bool confirmDelete,
  }) => repository.leaveCircle(circleId, confirmDelete: confirmDelete);

  Future<Result<AccountSummary, Failure>> getAccount() =>
      repository.getAccount();

  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) => repository.createSelfCircle(circle);

  Future<Result<CareCircleSummary, Failure>> createPatientCircle(
    NewPatientCircle circle,
  ) => repository.createPatientCircle(circle);

  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion) =>
      repository.deleteAccount(deletion);

  Future<Result<SentCircleRequest, Failure>> sendCircleRequest(
    NewCircleRequest request,
  ) => repository.sendCircleRequest(request);

  Future<Result<CircleInbox, Failure>> getInbox() => repository.getInbox();

  Future<Result<CircleRequestStatus, Failure>> respondToRequest(
    String id, {
    required bool accept,
  }) => repository.respondToRequest(id, accept: accept);

  Future<Result<String?, Failure>> respondToInvitation(
    String id, {
    required bool accept,
  }) => repository.respondToInvitation(id, accept: accept);

  Future<Result<(CareCircleSummary, CircleAppMode), Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  ) => repository.completeRequest(id, request);

  Future<Result<void, Failure>> cancelRequest(String id) =>
      repository.cancelRequest(id);

  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId) =>
      repository.getMedicalFile(circleId);

  /// The medical files saved on one page, for the other pages of the same
  /// circle that are open under it (the medical file page and the circle
  /// tab), so they show the new answers at once instead of reading the file
  /// from the server again.
  final StreamController<(String, MedicalFile)> _savedFiles =
      StreamController<(String, MedicalFile)>.broadcast();

  /// Each medical file of [circleId] saved from now on, the newest last.
  Stream<MedicalFile> medicalFileSaves(String circleId) => _savedFiles.stream
      .where(((String, MedicalFile) saved) => saved.$1 == circleId)
      .map(((String, MedicalFile) saved) => saved.$2);

  /// Tells the open pages that [file] is now the saved medical file of
  /// [circleId]. Called after the server accepted the change.
  void medicalFileSaved(String circleId, MedicalFile file) =>
      _savedFiles.add((circleId, file));

  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) => repository.updateMedicalProfile(circleId, profile);

  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  ) => repository.updatePatient(circleId, update);

  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  ) => repository.addContact(circleId, draft);

  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) => repository.updateContact(circleId, contactId, draft);

  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  ) => repository.deleteContact(circleId, contactId);

  Future<Result<EmergencyCard, Failure>> getEmergencyCard(String circleId) =>
      repository.getEmergencyCard(circleId);
}

/// What every part of the circles use case asks through.
mixin CirclesUseCaseScope {
  CirclesRepository get repository;
}
