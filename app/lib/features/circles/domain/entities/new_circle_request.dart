import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:equatable/equatable.dart';

/// What the sender typed to ask a patient who uses the app for a circle. The
/// circle does not exist yet: the patient has to agree first.
class NewCircleRequest extends Equatable {
  const NewCircleRequest({
    required this.patientPhoneNumber,
    required this.proposedAppMode,
  });

  /// The patient's number with the country code, `+9665XXXXXXXX`.
  final String patientPhoneNumber;

  final CircleAppMode proposedAppMode;

  @override
  List<Object?> get props => [patientPhoneNumber, proposedAppMode];
}

/// The state of a request on the sender's side.
enum CircleRequestStatus { pending, accepted, declined, other }

/// A request that the server saved, as the waiting page shows it.
class SentCircleRequest extends Equatable {
  const SentCircleRequest({
    required this.id,
    required this.patientPhoneNumber,
    required this.proposedAppMode,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String patientPhoneNumber;
  final CircleAppMode proposedAppMode;
  final CircleRequestStatus status;

  /// When the server saved the request. The account page says how long ago.
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    patientPhoneNumber,
    proposedAppMode,
    status,
    createdAt,
  ];
}
