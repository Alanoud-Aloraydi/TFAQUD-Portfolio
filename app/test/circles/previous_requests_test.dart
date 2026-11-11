import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/previous_requests.dart';
import 'package:flutter_test/flutter_test.dart';

SentCircleRequest _request(String id, CircleRequestStatus status) =>
    SentCircleRequest(
      id: id,
      patientPhoneNumber: '+966501234567',
      proposedAppMode: CircleAppMode.simplified,
      status: status,
    );

void main() {
  group('PreviousRequests', () {
    test('keeps only the requests the patient already answered', () {
      final CircleInbox inbox = CircleInbox(
        sent: <SentCircleRequest>[
          _request('open', CircleRequestStatus.pending),
          _request('accepted', CircleRequestStatus.accepted),
          _request('declined', CircleRequestStatus.declined),
        ],
        received: const [],
        invitations: const [],
      );

      final List<SentCircleRequest> previous = PreviousRequests.of(inbox);

      expect(previous.map((SentCircleRequest r) => r.id), <String>['declined']);
    });

    test('is empty when nothing was answered', () {
      expect(PreviousRequests.of(const CircleInbox.empty()), isEmpty);
    });
  });
}
