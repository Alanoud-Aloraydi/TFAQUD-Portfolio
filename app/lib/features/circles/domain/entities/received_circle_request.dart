import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:equatable/equatable.dart';

/// A request that asks the signed-in person to become the patient of a new
/// circle (CREAT-06). The sender typed the phone number, so the patient sees
/// the sender's name, the name the circle will get, and the mode proposed for
/// the patient's app.
class ReceivedCircleRequest extends Equatable {
  const ReceivedCircleRequest({
    required this.id,
    required this.status,
    required this.circleLabel,
    required this.circleName,
    required this.proposedAppMode,
    required this.requesterName,
    this.createdAt,
  });

  final String id;

  /// `pending` until the patient answers, then `accepted` until the patient
  /// completes the basic data and the circle is created.
  final CircleRequestStatus status;

  /// The word the circle is named with, for example "أمي".
  final String circleLabel;

  /// The label and the patient's first name, for example "أمي نورة".
  final String circleName;
  final CircleAppMode proposedAppMode;

  /// The display name of the sender, or the full name when there is none.
  final String requesterName;
  final DateTime? createdAt;

  /// The patient agreed and has not finished the basic data yet.
  bool get isAccepted => status == CircleRequestStatus.accepted;

  @override
  List<Object?> get props => [
    id,
    status,
    circleLabel,
    circleName,
    proposedAppMode,
    requesterName,
    createdAt,
  ];
}
