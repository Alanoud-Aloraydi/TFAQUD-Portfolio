import 'package:equatable/equatable.dart';

/// What the patient's answer led to.
enum ReplyOutcome {
  /// Nothing yet.
  none,

  /// The patient agreed. The page goes on to the basic data.
  accepted,

  /// The patient declined. The page goes back to the notifications.
  declined,
}

class RequestReplyState extends Equatable {
  const RequestReplyState({
    this.sending = false,
    this.outcome = ReplyOutcome.none,
    this.errorKey,
    this.sessionEnded = false,
  });

  final bool sending;
  final ReplyOutcome outcome;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;
  final bool sessionEnded;

  RequestReplyState copyWith({
    bool? sending,
    ReplyOutcome? outcome,
    String? errorKey,
    bool clearError = false,
    bool? sessionEnded,
  }) {
    return RequestReplyState(
      sending: sending ?? this.sending,
      outcome: outcome ?? this.outcome,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }

  @override
  List<Object?> get props => [sending, outcome, errorKey, sessionEnded];
}
