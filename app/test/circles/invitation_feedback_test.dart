import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/pending_invites_section.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/circles_fakes.dart';
import '../support/home_fakes.dart';
import '../support/widget_harness.dart';

void main() {
  setUpAll(initTestLocalization);

  late CirclesFakeRepository circles;
  late InboxCubit cubit;
  var accepted = 0;

  setUp(() async {
    accepted = 0;
    circles = CirclesFakeRepository()
      ..inbox = Success(
        CircleInbox(
          sent: [],
          received: [],
          invitations: [CirclesFakeRepository.invitedByKhaled],
        ),
      );
    cubit = InboxCubit(
      CirclesUseCase(circles),
      HomeUseCase(HomeFakeRepository()),
    );
    await cubit.load();
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester) => pumpArabic(
    tester,
    home: Scaffold(
      body: BlocBuilder<InboxCubit, InboxState>(
        bloc: cubit,
        builder: (context, state) => PendingInvitesSection(
          cubit: cubit,
          state: state,
          onAccepted: () => accepted++,
        ),
      ),
    ),
  );

  group('invitation feedback', () {
    testWidgets('accepting says so, then leaves', (tester) async {
      await open(tester);
      await tester.tap(find.text('circles.accept'.tr()));
      await tester.pump();
      await tester.pump();
      expect(find.text('toast.invite_accepted'.tr()), findsOneWidget);
      expect(accepted, 1);
    });

    testWidgets('declining says so', (tester) async {
      await open(tester);
      await tester.tap(find.text('circles.decline'.tr()));
      await tester.pump();
      await tester.pump();
      expect(find.text('toast.invite_declined'.tr()), findsOneWidget);
      expect(accepted, 0);
    });

    testWidgets('a failed answer shows no success message', (tester) async {
      circles.invitationReplied = const Error(NetworkFailure());
      await open(tester);
      await tester.tap(find.text('circles.accept'.tr()));
      await tester.pump();
      await tester.pump();
      expect(find.text('toast.invite_accepted'.tr()), findsNothing);
      expect(accepted, 0);
    });
  });
}
