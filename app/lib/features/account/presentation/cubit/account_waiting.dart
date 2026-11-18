import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';

/// The sent requests that wait for the patient. A declined one is not a
/// circle waiting for approval; the notifications page tells about it.
List<SentCircleRequest> waitingRequests(CircleInbox inbox) =>
    <SentCircleRequest>[
      for (final SentCircleRequest sent in inbox.sent)
        if (sent.status == CircleRequestStatus.pending ||
            sent.status == CircleRequestStatus.accepted)
          sent,
    ];
