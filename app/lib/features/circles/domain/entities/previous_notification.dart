import 'package:equatable/equatable.dart';

/// What an answered notification was.
enum PreviousKind {
  /// An invitation to join a circle, sent to the signed-in person.
  invitationReceived,

  /// An invitation the signed-in person sent.
  invitationSent,

  /// A request to make a circle for the signed-in person.
  requestReceived,

  /// A request the signed-in person sent to a patient.
  requestSent,
}

/// An invitation or a circle request that was already answered, shown in
/// the bell's «السابقة» for 30 days (the server drops it after).
class PreviousNotification extends Equatable {
  const PreviousNotification({
    required this.id,
    required this.kind,
    required this.accepted,
    required this.answeredAt,
    this.circleName,
    this.otherName,
    this.otherPhoneNumber,
  });

  final String id;
  final PreviousKind kind;

  /// Whether it ended with a yes (an accepted invitation, a completed
  /// request); false for a declined one.
  final bool accepted;
  final DateTime answeredAt;

  /// The circle, as the signed-in person reads its name; null for a request
  /// that made no circle.
  final String? circleName;

  /// The other person: who invited or asked, or who answered.
  final String? otherName;

  /// Their number, for someone with no name here (they have no account).
  final String? otherPhoneNumber;

  @override
  List<Object?> get props => [
    id,
    kind,
    accepted,
    answeredAt,
    circleName,
    otherName,
    otherPhoneNumber,
  ];
}
