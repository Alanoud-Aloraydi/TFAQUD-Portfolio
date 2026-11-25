import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/repositories/circle_requests_repository.dart';
import 'package:app/features/circles/domain/repositories/medical_file_repository.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

/// The circle operations the application needs, whatever provides them.
abstract class CirclesRepository
    implements
        CircleMembersRepository,
        CircleCreationRepository,
        CircleRequestsRepository,
        MedicalFileRepository {}

/// The account a circle starts from, creating a circle, and deleting
/// the account with what that does to its circles.
abstract class CircleCreationRepository {
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

  /// Deletes the account: DELETE /api/v1/accounts/me. The server asks for a
  /// choice first when one is needed ([PatientChoiceRequiredFailure],
  /// [LastManagerFailure]).
  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion);
}

/// Reading a circle, its name, and changing who is in it.
abstract class CircleMembersRepository {
  /// Read the members and pending invitations of one circle.
  Future<Result<CircleOverview, Failure>> getCircleOverview(String circleId);

  /// Names the circle: whoever changes the patient's picture may.
  Future<Result<void, Failure>> renameCircle(String circleId, String name);

  /// Invite a manager by verified account phone number.
  Future<Result<void, Failure>> inviteManager(
    String circleId,
    String phoneNumber,
  );

  Future<Result<void, Failure>> resendManagerInvitation(
    String circleId,
    String invitationId,
  );

  Future<Result<void, Failure>> cancelManagerInvitation(
    String circleId,
    String invitationId,
  );

  /// Whether a member may edit [area] («medications», «measurements»,
  /// «appointments»); only the circle's leader may say.
  Future<Result<void, Failure>> setMemberEditAccess(
    String circleId,
    String accountId, {
    required String area,
    required bool allowed,
  });

  Future<Result<void, Failure>> removeMember(String circleId, String accountId);

  /// Hands the circle's leadership to another member.
  Future<Result<void, Failure>> handOverLeadership(
    String circleId,
    String accountId,
  );

  Future<Result<void, Failure>> leaveCircle(
    String circleId, {
    required bool confirmDelete,
  });
}
