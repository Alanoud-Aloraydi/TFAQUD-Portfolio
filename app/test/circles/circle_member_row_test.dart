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

  Future<void> show(WidgetTester tester, {required bool canManageMembers}) =>
      pumpArabic(
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
            ),
          ),
        ),
      );

  testWidgets('the owner sees the switch and the remove button', (
    tester,
  ) async {
    await show(tester, canManageMembers: true);

    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.byTooltip('إزالة العضو'), findsOneWidget);
  });

  testWidgets('anyone else sees only the view-only badge', (tester) async {
    await show(tester, canManageMembers: false);

    expect(find.byType(Switch), findsNothing);
    expect(find.byTooltip('إزالة العضو'), findsNothing);
    expect(find.text('مشاهدة فقط'), findsOneWidget);
  });

  testWidgets('the switch sends the new choice', (tester) async {
    await show(tester, canManageMembers: true);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(circles.memberCalls.single, 'access:a-2:true');
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
