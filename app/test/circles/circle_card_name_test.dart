import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/circle_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

CircleOverview _overview({
  required bool canManage,
  required bool patientUsesApp,
}) => CircleOverview(
  name: 'دائرة نورة',
  patientName: 'نورة العتيبي',
  patientIsYou: false,
  patientUsesApp: patientUsesApp,
  patientBirthDate: DateTime(1954, 6, 5),
  city: 'بريدة',
  canManage: canManage,
  members: const <CircleMember>[CircleMember(name: 'Reem', isYou: true)],
  pendingInvitations: const <CirclePendingInvitation>[],
);

Future<void> _show(WidgetTester tester, CircleOverview overview) => pumpArabic(
  tester,
  home: Scaffold(
    body: CircleCardName(
      circleId: 'c-1',
      name: 'دائرة نورة',
      overview: overview,
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  // Built inside each test: `.tr()` returns the bare key until `setUpAll`
  // has loaded the Arabic texts.
  Finder pen() => find.byTooltip('circle_edit.title'.tr());

  testWidgets('a manager of a patient without the app has the one pen '
      'beside the name', (WidgetTester tester) async {
    await _show(tester, _overview(canManage: true, patientUsesApp: false));

    expect(find.text('دائرة نورة'), findsOneWidget);
    expect(pen(), findsOneWidget);
  });

  testWidgets('nobody else who cannot change the picture gets it', (
    WidgetTester tester,
  ) async {
    await _show(tester, _overview(canManage: true, patientUsesApp: true));
    expect(pen(), findsNothing);

    await _show(tester, _overview(canManage: false, patientUsesApp: false));
    expect(pen(), findsNothing);
  });
}
