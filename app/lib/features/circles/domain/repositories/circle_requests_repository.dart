import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

/// The requests and invitations between people, until a circle
/// exists or the request is gone.
abstract class CircleRequestsRepository {
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
  /// The second value is the account's own app mode right after this
  /// commits it, so the caller can switch shells immediately.
  Future<Result<(CareCircleSummary, CircleAppMode), Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  );

  /// The sender or the patient cancels a request that is not finished:
  /// DELETE /api/v1/circle-requests/{id}.
  Future<Result<void, Failure>> cancelRequest(String id);
}
