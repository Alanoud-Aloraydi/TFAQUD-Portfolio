import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';
import 'support/home_fakes.dart';

CircleInbox _inbox({
  bool request = true,
  bool agreed = false,
  bool invitation = true,
  bool declined = false,
}) => CircleInbox(
  sent: <SentCircleRequest>[
    if (declined)
      const SentCircleRequest(
        id: 'sent-1',
        patientPhoneNumber: '+966501234567',
        circleLabel: 'أمي',
        proposedAppMode: CircleAppMode.simplified,
        status: CircleRequestStatus.declined,
      ),
  ],
  received: <ReceivedCircleRequest>[
    if (request)
      agreed
          ? CirclesFakeRepository.agreedByNoura
          : CirclesFakeRepository.askedOfNoura,
  ],
  invitations: <ReceivedInvitation>[
    if (invitation) CirclesFakeRepository.invitedByKhaled,
  ],
);

void main() {
  late CirclesFakeRepository circles;
  late HomeUseCase home;
  late InboxCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    home = HomeUseCase(HomeFakeRepository());
    cubit = InboxCubit(CirclesUseCase(circles), home);
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('shows the loading state first, then the inbox', () async {
      circles.inbox = Success(_inbox());
      final Future<void> loading = cubit.load();
      expect(cubit.state.status, InboxStatus.loading);
      await loading;
      expect(cubit.state.status, InboxStatus.ready);
      expect(cubit.state.inbox.needsReply, 2);
    });

    test('an empty inbox needs no reply', () async {
      await cubit.load();
      expect(cubit.state.status, InboxStatus.ready);
      expect(cubit.state.inbox.needsReply, 0);
    });

    test('a failure of the first read says why and can be retried', () async {
      circles.inbox = const Error(NetworkFailure());
      await cubit.load();
      expect(cubit.state.status, InboxStatus.failure);
      expect(cubit.state.messageKey, 'error.network');
      circles.inbox = Success(_inbox());
      await cubit.load();
      expect(cubit.state.status, InboxStatus.ready);
    });

    test('a failure of a later read keeps the list', () async {
      circles.inbox = Success(_inbox());
      await cubit.load();
      circles.inbox = const Error(NetworkFailure());
      await cubit.load();
      expect(cubit.state.status, InboxStatus.ready);
      expect(cubit.state.inbox.needsReply, 2);
    });

    test('an ended sign-in is reported', () async {
      circles.inbox = const Error(SessionExpiredFailure());
      await cubit.load();
      expect(cubit.state.sessionEnded, isTrue);
    });
  });

  group('the bell cubit', () {
    test('reads again whenever the circles change', () async {
      final InboxCubit bell = InboxCubit(
        CirclesUseCase(circles),
        home,
        followCircleChanges: true,
      );
      addTearDown(bell.close);
      await bell.load();
      expect(circles.inboxReads, 1);
      circles.inbox = Success(_inbox(request: false, invitation: false));
      home.notifyCirclesChanged(select: 'circle-1');
      await pumpEventQueue();
      expect(circles.inboxReads, 2);
    });

    test('the cubit of the page does not follow the changes', () async {
      await cubit.load();
      home.notifyCirclesChanged();
      await pumpEventQueue();
      expect(circles.inboxReads, 1);
    });
  });

  group('an invitation', () {
    setUp(() async {
      circles.inbox = Success(_inbox());
      await cubit.load();
    });

    test('accepting it removes the card and selects the circle', () async {
      final Future<String?> signal = home.changes.first;
      circles.inbox = Success(_inbox(invitation: false));
      expect(await cubit.respondToInvitation('invitation-1', accept: true),
          isTrue);
      expect(await signal, 'circle-from-invitation');
      expect(
        circles.invitationAnswers.single,
        ('invitation-1', true),
      );
      await pumpEventQueue();
      expect(cubit.state.inbox.invitations, isEmpty);
      expect(cubit.state.busyIds, isEmpty);
    });

    test('declining it adds no circle', () async {
      circles.invitationReplied = const Success<String?, Failure>(null);
      circles.inbox = Success(_inbox(invitation: false));
      var notified = false;
      final sub = home.changes.listen((_) => notified = true);
      addTearDown(sub.cancel);
      expect(await cubit.respondToInvitation('invitation-1', accept: false),
          isTrue);
      await pumpEventQueue();
      expect(notified, isFalse);
      expect(cubit.state.inbox.invitations, isEmpty);
    });

    test('a refusal keeps the card and says why', () async {
      circles.invitationReplied = const Error(ReplyModeConflictFailure());
      expect(await cubit.respondToInvitation('invitation-1', accept: true),
          isFalse);
      expect(cubit.state.errorKey, 'circles.reply_mode_conflict');
      expect(cubit.state.inbox.invitations, hasLength(1));
      expect(cubit.state.busyIds, isEmpty);
    });

    test('an invitation that is gone makes the list load again', () async {
      circles.invitationReplied = const Error(RequestUnavailableFailure());
      circles.inbox = Success(_inbox(invitation: false));
      expect(await cubit.respondToInvitation('invitation-1', accept: true),
          isFalse);
      await pumpEventQueue();
      expect(cubit.state.errorKey, 'circles.request_unavailable');
      expect(cubit.state.inbox.invitations, isEmpty);
    });
  });

  group('cancel', () {
    test('cancels an accepted request and reads the list again', () async {
      circles.inbox = Success(_inbox(agreed: true));
      await cubit.load();
      circles.inbox = Success(_inbox(request: false));
      expect(await cubit.cancelRequest('request-in-1'), isTrue);
      expect(circles.canceledIds, <String>['request-in-1']);
      await pumpEventQueue();
      expect(cubit.state.inbox.received, isEmpty);
    });

    test('a refusal says why', () async {
      circles.canceled = const Error(NetworkFailure());
      expect(await cubit.cancelRequest('request-in-1'), isFalse);
      expect(cubit.state.errorKey, 'error.network');
    });

    test('the message is cleared once the page showed it', () async {
      circles.canceled = const Error(NetworkFailure());
      await cubit.cancelRequest('request-in-1');
      cubit.errorShown();
      expect(cubit.state.errorKey, isNull);
    });
  });
}
