import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';

/// Splits the inbox into what is still open and what is already answered.
abstract class PreviousRequests {
  PreviousRequests._();

  /// The requests the person sent that the patient already answered. The
  /// server keeps them for a few days; its `status` says they are handled.
  static List<SentCircleRequest> of(CircleInbox inbox) => <SentCircleRequest>[
    for (final SentCircleRequest sent in inbox.sent)
      if (sent.status == CircleRequestStatus.declined) sent,
  ];
}
