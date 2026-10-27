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
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class CirclesRepositoryDomain {
  /// The signed-in account: GET /api/v1/accounts/me.
  Future<Result<AccountSummary, Failure>> getAccount();

  /// Creates the circle of the signed-in person for their own care:
  /// POST /api/v1/circles/self. Returns the new circle.
  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  );

  /// Creates a circle for a patient who does not use the app, managed by the
  /// signed-in person: POST /api/v1/circles/patient-without-account.
  Future<Result<CareCircleSummary, Failure>> createPatientCircle(
    NewPatientCircle circle,
  );

  /// Asks a patient who uses the app for a circle: POST /api/v1/circle-requests.
  /// The circle exists only after the patient agrees and completes it.
  Future<Result<SentCircleRequest, Failure>> sendCircleRequest(
    NewCircleRequest request,
  );

  /// What waits for an answer and what was sent: GET /api/v1/circle-requests
  /// and GET /api/v1/invitations, read together.
  Future<Result<CircleInbox, Failure>> getInbox();

  /// The patient agrees to or declines a request:
  /// POST /api/v1/circle-requests/{id}/respond. Agreeing does not create the
  /// circle. Returns the status the server saved.
  Future<Result<CircleRequestStatus, Failure>> respondToRequest(
    String id, {
    required bool accept,
  });

  /// The invited person accepts or declines an invitation to manage a circle:
  /// POST /api/v1/invitations/{id}/respond. Returns the id of the circle when
  /// the invitation was accepted, and null when it was declined.
  Future<Result<String?, Failure>> respondToInvitation(
    String id, {
    required bool accept,
  });

  /// The patient gives the basic data of an accepted request:
  /// POST /api/v1/circle-requests/{id}/complete. This creates the circle.
  Future<Result<CareCircleSummary, Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  );

  /// The sender or the patient cancels a request that is not finished:
  /// DELETE /api/v1/circle-requests/{id}.
  Future<Result<void, Failure>> cancelRequest(String id);

  /// Deletes the account: DELETE /api/v1/accounts/me. The server asks for a
  /// choice first when one is needed ([PatientChoiceRequiredFailure],
  /// [LastManagerFailure]).
  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion);

  /// The medical file of a circle: GET /api/v1/circles/{id}/medical-profile.
  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId);

  /// Saves the health answers: PATCH /api/v1/circles/{id}/medical-profile. A
  /// part with no answer is cleared back to "unknown". Returns what the server
  /// saved.
  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  );

  /// Saves the birth date, the city and, for a patient without an account, the
  /// names: PUT /api/v1/circles/{id}/patient.
  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  );

  /// Adds an emergency contact: POST /api/v1/circles/{id}/emergency-contacts.
  /// [TooManyContactsFailure] and [DuplicateContactFailure] are the refusals
  /// that have their own text.
  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  );

  /// Changes an emergency contact: PUT
  /// /api/v1/circles/{id}/emergency-contacts/{contactId}.
  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  );

  /// Removes an emergency contact: DELETE
  /// /api/v1/circles/{id}/emergency-contacts/{contactId}.
  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  );

  /// The read-only emergency card: GET /api/v1/circles/{id}/emergency-card.
  Future<Result<EmergencyCard, Failure>> getEmergencyCard(String circleId);
}
