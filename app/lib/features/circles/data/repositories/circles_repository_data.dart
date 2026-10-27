import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/models/circle_request_model.dart';
import 'package:app/features/circles/data/models/complete_circle_request_model.dart';
import 'package:app/features/circles/data/models/new_patient_circle_model.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
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
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: CirclesRepositoryDomain)
class CirclesRepositoryData implements CirclesRepositoryDomain {
  CirclesRepositoryData(this._remote);

  final BaseCirclesRemoteDataSource _remote;

  @override
  Future<Result<AccountSummary, Failure>> getAccount() async {
    try {
      return Success((await _remote.getAccount()).toEntity());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) async {
    try {
      final created = await _remote.createSelfCircle(
        NewSelfCircleModel(circle),
      );
      return Success(created.toEntity());
    } catch (error) {
      return Error(_circleFailure(error));
    }
  }

  @override
  Future<Result<CareCircleSummary, Failure>> createPatientCircle(
    NewPatientCircle circle,
  ) async {
    try {
      final created = await _remote.createPatientCircle(
        NewPatientCircleModel(circle),
      );
      return Success(created.toEntity());
    } catch (error) {
      return Error(_circleFailure(error));
    }
  }

  @override
  Future<Result<SentCircleRequest, Failure>> sendCircleRequest(
    NewCircleRequest request,
  ) async {
    try {
      final sent = await _remote.sendCircleRequest(
        NewCircleRequestModel(request),
      );
      return Success(sent.toEntity());
    } catch (error) {
      return Error(_requestFailure(error));
    }
  }

  @override
  Future<Result<CircleInbox, Failure>> getInbox() async {
    try {
      // The two lists are independent, so they are read at the same time.
      final List<Object> answers = await Future.wait<Object>(<Future<Object>>[
        _remote.getCircleRequests(),
        _remote.getInvitations(),
      ]);
      final CircleRequestsModel requests = answers[0] as CircleRequestsModel;
      return Success(
        CircleInbox(
          sent: requests.sent,
          received: requests.received,
          invitations: answers[1] as List<ReceivedInvitation>,
        ),
      );
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<CircleRequestStatus, Failure>> respondToRequest(
    String id, {
    required bool accept,
  }) async {
    try {
      final answer = await _remote.respondToRequest(id, accept: accept);
      return Success(answer.toEntity().status);
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }

  @override
  Future<Result<String?, Failure>> respondToInvitation(
    String id, {
    required bool accept,
  }) async {
    try {
      return Success<String?, Failure>(
        await _remote.respondToInvitation(id, accept: accept),
      );
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }

  @override
  Future<Result<CareCircleSummary, Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  ) async {
    try {
      final created = await _remote.completeRequest(
        id,
        CompleteCircleRequestModel(request),
      );
      return Success(created.toEntity());
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> cancelRequest(String id) async {
    try {
      await _remote.cancelRequest(id);
      return const Success(null);
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion) async {
    try {
      await _remote.deleteAccount(deletion);
      return const Success(null);
    } catch (error) {
      return Error(
        switch (apiErrorCodeOf(error)) {
          ApiErrorCodes.patientChoiceRequired =>
            const PatientChoiceRequiredFailure(),
          ApiErrorCodes.lastManager => const LastManagerFailure(),
          _ => FailureExceptions.getException(error),
        },
      );
    }
  }

  @override
  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId) async {
    try {
      return Success(await _remote.getMedicalFile(circleId));
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) async {
    try {
      return Success(await _remote.updateMedicalProfile(circleId, profile));
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  ) async {
    try {
      await _remote.updatePatient(circleId, update);
      return const Success(null);
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }

  @override
  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  ) async {
    try {
      return Success(await _remote.addContact(circleId, draft));
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }

  @override
  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) async {
    try {
      return Success(await _remote.updateContact(circleId, contactId, draft));
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  ) async {
    try {
      await _remote.deleteContact(circleId, contactId);
      return const Success(null);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<EmergencyCard, Failure>> getEmergencyCard(
    String circleId,
  ) async {
    try {
      return Success(await _remote.getEmergencyCard(circleId));
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  /// The API codes that have their own text; every other error is read by
  /// [FailureExceptions].
  Failure _circleFailure(Object error) {
    return switch (apiErrorCodeOf(error)) {
      ApiErrorCodes.alreadyHasCircle => const AlreadyHasCircleFailure(),
      ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
      ApiErrorCodes.invalidBirthDate => const InvalidBirthDateFailure(),
      ApiErrorCodes.modeConflict => const ModeConflictFailure(),
      _ => FailureExceptions.getException(error),
    };
  }

  /// The same for a request. `already_has_circle` here is about the patient,
  /// not about the signed-in account, so it has its own text.
  Failure _requestFailure(Object error) {
    return switch (apiErrorCodeOf(error)) {
      ApiErrorCodes.alreadyHasCircle => const PatientHasCircleFailure(),
      ApiErrorCodes.selfRequest => const SelfRequestFailure(),
      ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
      ApiErrorCodes.modeConflict => const ModeConflictFailure(),
      _ => FailureExceptions.getException(error),
    };
  }

  /// The same for saving the medical file and the emergency contacts.
  Failure _medicalFailure(Object error) {
    return switch (apiErrorCodeOf(error)) {
      ApiErrorCodes.tooManyContacts => const TooManyContactsFailure(),
      ApiErrorCodes.duplicateContact => const DuplicateContactFailure(),
      ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
      ApiErrorCodes.invalidBirthDate => const InvalidBirthDateFailure(),
      _ => FailureExceptions.getException(error),
    };
  }

  /// The same for the answers of the person a request or an invitation is
  /// addressed to, and for completing and canceling a request.
  Failure _replyFailure(Object error) {
    return switch (apiErrorCodeOf(error)) {
      ApiErrorCodes.requestNotPending ||
      ApiErrorCodes.requestNotCancelable ||
      ApiErrorCodes.invitationNotPending ||
      ApiErrorCodes.alreadyManager ||
      ApiErrorCodes.consentRequired => const RequestUnavailableFailure(),
      ApiErrorCodes.alreadyHasCircle => const AlreadyHasCircleFailure(),
      ApiErrorCodes.acceptedRequestExists =>
        const AcceptedRequestExistsFailure(),
      ApiErrorCodes.modeConflict => const ReplyModeConflictFailure(),
      ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
      ApiErrorCodes.invalidBirthDate => const InvalidBirthDateFailure(),
      _ => FailureExceptions.getException(error),
    };
  }
}
