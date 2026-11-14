import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:equatable/equatable.dart';

/// Everything the signed-in person has to answer or follow, read from the
/// server in one go: the requests they sent, the requests addressed to their
/// number, the invitations to manage a circle, and what was answered in the
/// last 30 days.
class CircleInbox extends Equatable {
  CircleInbox({
    required List<SentCircleRequest> sent,
    required List<ReceivedCircleRequest> received,
    required List<ReceivedInvitation> invitations,
    List<PreviousNotification> previous = const <PreviousNotification>[],
  }) : sent = List<SentCircleRequest>.unmodifiable(sent),
       received = List<ReceivedCircleRequest>.unmodifiable(received),
       invitations = List<ReceivedInvitation>.unmodifiable(invitations),
       previous = List<PreviousNotification>.unmodifiable(previous);

  const CircleInbox.empty()
    : sent = const <SentCircleRequest>[],
      received = const <ReceivedCircleRequest>[],
      invitations = const <ReceivedInvitation>[],
      previous = const <PreviousNotification>[];

  /// Requests this account sent that are still open, and the ones the patient
  /// declined in the last days (those are told in [previous]).
  final List<SentCircleRequest> sent;

  /// Requests that name this account's number: waiting for an answer, or
  /// accepted and waiting for the basic data.
  final List<ReceivedCircleRequest> received;
  final List<ReceivedInvitation> invitations;

  /// The invitations and requests answered in the last 30 days, newest
  /// first: the bell's «السابقة».
  final List<PreviousNotification> previous;

  /// How many things wait for an answer. The bell shows a dot when this is not
  /// zero.
  int get needsReply => received.length + invitations.length;

  @override
  List<Object?> get props => [sent, received, invitations, previous];
}
