import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
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

/// The number of the request is the sender's own number.
class SelfRequestFailure extends Failure {
  const SelfRequestFailure() : super('circles.self_request');
}

/// The person the request names is already the patient of a circle, and a
/// person can be the patient of only one.
class PatientHasCircleFailure extends Failure {
  const PatientHasCircleFailure() : super('circles.patient_has_circle');
}

/// The request or the invitation is no longer open: the sender canceled it, or
/// it was answered or completed already.
class RequestUnavailableFailure extends Failure {
  const RequestUnavailableFailure() : super('circles.request_unavailable');
}

/// The patient already agreed to another request and has not finished its
/// details. Only one can be open.
class AcceptedRequestExistsFailure extends Failure {
  const AcceptedRequestExistsFailure()
    : super('circles.accepted_request_exists');
}

/// The mode of the account does not fit what the request or the invitation
/// needs. The mode of an account never changes.
class ReplyModeConflictFailure extends Failure {
  const ReplyModeConflictFailure() : super('circles.reply_mode_conflict');
}
