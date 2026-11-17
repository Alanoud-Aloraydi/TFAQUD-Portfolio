import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

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
