import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/pages/approved_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/notifications_screen.dart';
import 'package:app/features/circles/presentation/pages/request_reply_screen.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/app_shell_harness.dart';
import '../support/circles_fakes.dart';

void main() {
  setUpShellApp();

  group('Notifications', () {
    CircleInbox inboxOf({
      List<SentCircleRequest> sent = const <SentCircleRequest>[],
      List<ReceivedCircleRequest> received = const <ReceivedCircleRequest>[],
      List<ReceivedInvitation> invitations = const <ReceivedInvitation>[],
    }) => CircleInbox(sent: sent, received: received, invitations: invitations);

    /// The bell as the top bar names it for [count] things that wait.
    Finder bell(int count) => find.byTooltip(
      count == 0
          ? 'topbar.notifications'.tr()
          : 'topbar.notifications_new'.tr(args: <String>['$count']),
    );

    Future<void> openNotifications(WidgetTester tester, int waiting) async {
      tallPhone(tester);
      await pumpApp(tester);
      await tester.tap(bell(waiting));
      await tester.pumpAndSettle();
    }

    final CircleInbox oneOfEach = inboxOf(
      received: const <ReceivedCircleRequest>[
        CirclesFakeRepository.askedOfNoura,
      ],
      invitations: const <ReceivedInvitation>[
        CirclesFakeRepository.invitedByKhaled,
      ],
    );

    testWidgets('the bell shows a dot and says how many things wait', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(oneOfEach);
      await pumpApp(tester);

      expect(find.byType(Badge), findsOneWidget);
      expect(bell(2), findsOneWidget);
      expect(find.byTooltip('topbar.notifications'.tr()), findsNothing);
    });

    testWidgets('with nothing waiting there is no dot', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(Badge), findsNothing);
      expect(bell(0), findsOneWidget);
    });

    testWidgets('a request the person already agreed to still counts', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          received: const <ReceivedCircleRequest>[
            CirclesFakeRepository.agreedByNoura,
          ],
        ),
      );
      await pumpApp(tester);
      expect(bell(1), findsOneWidget);
    });

    testWidgets('the bell opens the page with the invitation and the request', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(oneOfEach);
      await openNotifications(tester, 2);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      // The bell's page is a modal too: it rises from the bottom.
      final PageRoute<dynamic> route =
          ModalRoute.of(tester.element(find.byType(NotificationsScreen)))!
              as PageRoute<dynamic>;
      expect(route.fullscreenDialog, isTrue);
      expect(
        find.text('circles.needs_reply'.tr(args: <String>['2'])),
        findsOneWidget,
      );
      expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
      expect(
        find.text(
          'circles.invitation_body_by'.tr(args: <String>['خالد', 'أمي نورة']),
        ),
        findsOneWidget,
      );
      expect(find.text('circles.request_card_title'.tr()), findsOneWidget);
      expect(
        find.text(
          'circles.request_card_body'.tr(args: <String>['سارة الحربي']),
        ),
        findsOneWidget,
      );
      expect(find.text('circles.view_request'.tr()), findsOneWidget);
    });

    testWidgets('the bell opens a page that says nothing waits', (
      WidgetTester tester,
    ) async {
      await openNotifications(tester, 0);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
    });

    testWidgets('a request the patient declined is told under the events', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          sent: const <SentCircleRequest>[
            SentCircleRequest(
              id: 'request-1',
              patientPhoneNumber: '+966501234567',
              proposedAppMode: CircleAppMode.simplified,
              status: CircleRequestStatus.declined,
            ),
          ],
        ),
      );
      // A declined request needs no answer, so there is no dot.
      await openNotifications(tester, 0);

      expect(find.text('circles.events_title'.tr()), findsOneWidget);
      expect(find.text('circles.declined_title'.tr()), findsOneWidget);
      expect(find.text('circles.declined_body'.tr()), findsOneWidget);
      expect(find.text('+966 50 123 4567'), findsOneWidget);
      expect(find.text('circles.inbox_empty'.tr()), findsNothing);
    });

    testWidgets('a request still waiting for the patient is not an event', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          sent: const <SentCircleRequest>[CirclesFakeRepository.waitingRequest],
        ),
      );
      await openNotifications(tester, 0);

      expect(find.text('circles.events_title'.tr()), findsNothing);
      expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
    });

    testWidgets(
      'accepting an invitation sends the answer and clears the card',
      (WidgetTester tester) async {
        circles.inbox = Success(
          inboxOf(
            invitations: const <ReceivedInvitation>[
              CirclesFakeRepository.invitedByKhaled,
            ],
          ),
        );
        await openNotifications(tester, 1);
        // The server no longer lists the invitation once it was answered.
        circles.inbox = const Success(CircleInbox.empty());

        await tester.tap(find.text('circles.accept'.tr()));
        await tester.pumpAndSettle();

        expect(circles.invitationAnswers.single, ('invitation-1', true));
        expect(find.text('circles.invitation_title'.tr()), findsNothing);
        expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
      },
    );

    testWidgets('declining an invitation sends "no"', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          invitations: const <ReceivedInvitation>[
            CirclesFakeRepository.invitedByKhaled,
          ],
        ),
      );
      circles.invitationReplied = const Success<String?, Failure>(null);
      await openNotifications(tester, 1);
      circles.inbox = const Success(CircleInbox.empty());

      await tester.tap(find.text('circles.decline'.tr()));
      await tester.pumpAndSettle();

      expect(circles.invitationAnswers.single, ('invitation-1', false));
      expect(find.text('circles.invitation_title'.tr()), findsNothing);
    });

    testWidgets('a refused answer shows its text and keeps the card', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          invitations: const <ReceivedInvitation>[
            CirclesFakeRepository.invitedByKhaled,
          ],
        ),
      );
      circles.invitationReplied = const Error(RequestUnavailableFailure());
      await openNotifications(tester, 1);

      await tester.tap(find.text('circles.accept'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('circles.request_unavailable'.tr()), findsOneWidget);
      expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
    });

    testWidgets('a person who cannot be reached sees a retry button', (
      WidgetTester tester,
    ) async {
      tallPhone(tester);
      await pumpApp(tester);
      // The page reads the list again, and that read fails.
      circles.inbox = const Error(NetworkFailure());
      await tester.tap(bell(0));
      await tester.pumpAndSettle();

      expect(find.text('error.network'.tr()), findsOneWidget);
      circles.inbox = Success(oneOfEach);
      await tester.tap(find.text('auth.retry'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
    });

    group('a request from someone else', () {
      Future<void> openRequest(WidgetTester tester) async {
        circles.inbox = Success(oneOfEach);
        await openNotifications(tester, 2);
        await tester.tap(find.text('circles.view_request'.tr()));
        await tester.pumpAndSettle();
      }

      testWidgets('the request page says who asks and what is asked', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);

        expect(find.byType(RequestReplyScreen), findsOneWidget);
        expect(find.text('circles.reply_title'.tr()), findsOneWidget);
        expect(find.text('سارة الحربي'), findsOneWidget);
        // No circle name yet: the patient names it after agreeing.
        expect(find.text('أمي نورة'), findsNothing);
        expect(find.text('circles.mode_simplified'.tr()), findsOneWidget);
        expect(find.text('circles.reply_body_simplified'.tr()), findsOneWidget);
        expect(find.text('circles.reply_decline_note'.tr()), findsOneWidget);
        expect(find.text('circles.accept_request'.tr()), findsOneWidget);
        expect(find.text('circles.decline'.tr()), findsOneWidget);
      });

      testWidgets('the detailed mode is explained in its own words', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(
          inboxOf(
            received: const <ReceivedCircleRequest>[
              ReceivedCircleRequest(
                id: 'request-in-2',
                status: CircleRequestStatus.pending,
                circleName: 'أبي سعد',
                proposedAppMode: CircleAppMode.detailed,
                requesterName: 'خالد',
              ),
            ],
          ),
        );
        await openNotifications(tester, 1);
        await tester.tap(find.text('circles.view_request'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.mode_detailed'.tr()), findsOneWidget);
        expect(find.text('circles.reply_body_detailed'.tr()), findsOneWidget);
        expect(find.text('circles.reply_body_simplified'.tr()), findsNothing);
      });

      testWidgets('agreeing sends "yes" and opens the page of the basic data', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);

        await tester.tap(find.text('circles.accept_request'.tr()));
        await tester.pumpAndSettle();

        expect(circles.requestAnswers.single, ('request-in-1', true));
        expect(find.byType(RequestReplyScreen), findsNothing);
        expect(find.byType(ApprovedCircleBasicsScreen), findsOneWidget);
        // The patient names the circle with the chips of their own circle;
        // the name is the account's.
        expect(find.text('circles.preset.care'.tr()), findsOneWidget);
        expect(find.text('circles.name_hint'.tr()), findsOneWidget);
        expect(find.text('أمي نورة'), findsNothing);
        expect(find.text('Reem Alahmadi'), findsOneWidget);
        // Nothing was created yet: the circle exists after the last step.
        expect(circles.completions, isEmpty);
      });

      testWidgets('declining sends "no" and goes back to the notifications', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);
        circles.replied = const Success(CircleRequestStatus.declined);
        circles.inbox = Success(
          inboxOf(
            invitations: const <ReceivedInvitation>[
              CirclesFakeRepository.invitedByKhaled,
            ],
          ),
        );

        await tester.tap(find.text('circles.decline'.tr()));
        await tester.pumpAndSettle();

        expect(circles.requestAnswers.single, ('request-in-1', false));
        expect(find.byType(RequestReplyScreen), findsNothing);
        expect(find.byType(NotificationsScreen), findsOneWidget);
        // The page read the list again: the request is gone.
        expect(find.text('circles.request_card_title'.tr()), findsNothing);
        expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
      });

      testWidgets('a request that is gone shows its text and stays', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);
        circles.replied = const Error(RequestUnavailableFailure());

        await tester.tap(find.text('circles.accept_request'.tr()));
        await tester.pumpAndSettle();

        expect(find.byType(RequestReplyScreen), findsOneWidget);
        expect(find.text('circles.request_unavailable'.tr()), findsOneWidget);
        expect(find.byType(ApprovedCircleBasicsScreen), findsNothing);
      });

      testWidgets('going back leaves the request unanswered', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);

        await tester.tap(find.text('common.back'.tr()));
        await tester.pumpAndSettle();

        expect(circles.requestAnswers, isEmpty);
        expect(find.byType(NotificationsScreen), findsOneWidget);
        expect(find.text('circles.view_request'.tr()), findsOneWidget);
      });
    });

    group('a request the person agreed to', () {
      final CircleInbox agreed = inboxOf(
        received: const <ReceivedCircleRequest>[
          CirclesFakeRepository.agreedByNoura,
        ],
      );

      testWidgets('waits for the basic data on the page', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);

        expect(find.text('circles.complete_card_title'.tr()), findsOneWidget);
        expect(
          find.text(
            'circles.complete_card_body'.tr(args: <String>['سارة الحربي']),
          ),
          findsOneWidget,
        );
        expect(find.text('circles.view_request'.tr()), findsNothing);
      });

      testWidgets('continue opens the basic data page', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);

        await tester.tap(find.text('common.continue'.tr()));
        await tester.pumpAndSettle();

        expect(find.byType(ApprovedCircleBasicsScreen), findsOneWidget);
        expect(find.text('circles.preset.health'.tr()), findsOneWidget);
      });

      testWidgets('one tap creates the circle from the request', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);
        await tester.tap(find.text('common.continue'.tr()));
        await tester.pumpAndSettle();

        // An account from before onboarding gives its birth date and city
        // here. The date and the city sheets are covered by the first flow.
        final CreateCircleCubit cubit = tester
            .element(find.byType(ApprovedCircleBasicsScreen))
            .read<CreateCircleCubit>();
        cubit.birthDateChanged(DateTime(1954, 6, 5));
        cubit.cityChanged('بريدة');
        await tester.pump();
        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        expect(circles.completedIds, <String>['request-in-1']);
        final completion = circles.completions.single;
        // The first chip is chosen unless the patient picks another.
        expect(completion.name, 'circles.preset.care'.tr());
        expect(completion.birthDate, DateTime(1954, 6, 5));
        expect(completion.city, 'بريدة');
        // The patient's circle was made from the request, not by a new one.
        expect(circles.requests, isEmpty);
        expect(circles.patientCircles, isEmpty);
        expect(find.byType(AppBottomBar), findsOneWidget);
      });

      testWidgets('canceling asks first and keeps the request on "no"', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);

        await tester.tap(find.text('circles.cancel_request'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('circles.cancel_confirm_title'.tr()), findsOneWidget);
        expect(
          find.text('circles.cancel_confirm_body_patient'.tr()),
          findsOneWidget,
        );

        await tester.tap(find.text('circles.cancel_confirm_no'.tr()));
        await tester.pumpAndSettle();

        expect(circles.canceledIds, isEmpty);
        expect(find.text('circles.complete_card_title'.tr()), findsOneWidget);
      });

      testWidgets(
        'canceling on "yes" cancels this request and clears the card',
        (WidgetTester tester) async {
          circles.inbox = Success(agreed);
          await openNotifications(tester, 1);
          circles.inbox = const Success(CircleInbox.empty());

          await tester.tap(find.text('circles.cancel_request'.tr()));
          await tester.pumpAndSettle();
          await tester.tap(find.text('circles.cancel_confirm_yes'.tr()));
          await tester.pumpAndSettle();

          expect(circles.canceledIds, <String>['request-in-1']);
          expect(find.text('circles.complete_card_title'.tr()), findsNothing);
          expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
        },
      );
    });

    group('pages that need a request', () {
      testWidgets(
        'the request page opened without a request goes to the list',
        (WidgetTester tester) async {
          await pumpApp(tester);
          AppRouter.router.go(Routes.replyRequest);
          await tester.pumpAndSettle();

          expect(find.byType(RequestReplyScreen), findsNothing);
          expect(find.byType(NotificationsScreen), findsOneWidget);
        },
      );

      for (final String route in <String>[Routes.completeRequest]) {
        testWidgets('$route opened without a request goes to the list', (
          WidgetTester tester,
        ) async {
          await pumpApp(tester);
          AppRouter.router.go(route);
          await tester.pumpAndSettle();

          expect(find.byType(ApprovedCircleBasicsScreen), findsNothing);
          expect(find.byType(NotificationsScreen), findsOneWidget);
        });
      }
    });
  });
}
