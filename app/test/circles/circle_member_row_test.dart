import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_member_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/circles_fakes.dart';
import '../support/widget_harness.dart';

const CircleMember _paused = CircleMember(
  name: 'Lina',
  isYou: false,
  accountId: 'a-2',
  isManager: false,
);

void main() {
  late CirclesFakeRepository circles;
  late CircleOverviewCubit cubit;

  setUpAll(initTestLocalization);

  setUp(() async {
    circles = CirclesFakeRepository();
    cubit = CircleOverviewCubit(CirclesUseCase(circles), 'circle-1');
    await cubit.load();
  });

  tearDown(() => cubit.close());

  Future<void> show(
    WidgetTester tester, {
    required bool canManageMembers,
    bool canHandOver = false,
  }) => pumpArabic(
    tester,
    home: Scaffold(
      body: BlocProvider<CircleOverviewCubit>.value(
        value: cubit,
        child: CircleMemberRow(
          member: _paused,
          circleId: 'circle-1',
          patientUsesApp: true,
          patientIsYou: true,
          canManageMembers: canManageMembers,
          canHandOver: canHandOver,
        ),
      ),
    ),
  );

  FilterChip chip(WidgetTester tester, String label) =>
      tester.widget(find.widgetWithText(FilterChip, label));

  testWidgets('the leader sees a chip for each area and the remove button', (
    tester,
  ) async {
    await show(tester, canManageMembers: true);

    for (final String label in <String>['الأدوية', 'القياسات', 'المواعيد']) {
      expect(chip(tester, label).selected, isFalse);
    }
    expect(find.text('إزالة العضو'), findsOneWidget);
    // Handing over is offered only where the leader may.
    expect(find.text('تسليم القيادة'), findsNothing);
  });

  testWidgets('anyone else sees only the view-only badge', (tester) async {
    await show(tester, canManageMembers: false);

    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('إزالة العضو'), findsNothing);
    expect(find.text('مشاهدة فقط'), findsOneWidget);
  });

  testWidgets('a chip lets the member edit that area only', (tester) async {
    await show(tester, canManageMembers: true);

    await tester.tap(find.widgetWithText(FilterChip, 'القياسات'));
    await tester.pumpAndSettle();

    expect(circles.memberCalls.single, 'access:a-2:measurements:true');
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('the leader hands the circle over after confirming', (
    tester,
  ) async {
    await show(tester, canManageMembers: true, canHandOver: true);

    await tester.tap(find.text('تسليم القيادة'));
    await tester.pumpAndSettle();
    expect(circles.memberCalls, isEmpty);
    // The alert's own button, over the row's.
    await tester.tap(find.text('تسليم القيادة').last);
    await tester.pumpAndSettle();

    expect(circles.memberCalls.single, 'leader:a-2');
  });
}
