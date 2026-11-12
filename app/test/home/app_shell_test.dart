import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:app/features/shell/widgets/glass_add_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/app_shell_harness.dart';
import '../support/home_fakes.dart';

void main() {
  setUpShellApp();

  group('AppShell', () {
    testWidgets('nothing dims the tab pages', (WidgetTester tester) async {
      await pumpApp(tester);

      // A tab page is see-through; a tinted barrier under it would darken
      // the whole tab and leave a lighter band under the top bar.
      expect(
        find.descendant(
          of: find.byType(FadingBranches),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is ModalBarrier && (widget.color?.a ?? 0) > 0,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('shows the top bar actions, four tabs and the add button', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.notifications'.tr()), findsOneWidget);
      expect(find.byType(HomeWidget), findsOneWidget);
      expect(find.byTooltip('tab.add'.tr()), findsOneWidget);
      expect(
        tester.widget<GlassAddButton>(find.byType(GlassAddButton)).onPressed,
        isNull,
      );
      final account = tester.getCenter(find.byTooltip('topbar.account'.tr()));
      final switcher = tester.getCenter(find.byType(HomeWidget));
      final bell = tester.getCenter(
        find.byTooltip('topbar.notifications'.tr()),
      );
      // Right to left: the account at the start (right), the circle switcher
      // in the middle, the bell at the end (left).
      expect(account.dx, greaterThan(switcher.dx));
      expect(switcher.dx, greaterThan(bell.dx));
      for (final String key in <String>[
        'tab.today',
        'tab.plan',
        'tab.record',
        'tab.circle',
      ]) {
        expect(inBar(key.tr()), findsWidgets);
      }
    });

    testWidgets('every tab keeps both bars and selection', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await chooseCircle(tester, 'Circle two');

      for (final String key in <String>[
        'tab.plan',
        'tab.record',
        'tab.circle',
        'tab.today',
      ]) {
        await tester.tap(inBar(key.tr()).first);
        await tester.pumpAndSettle();
        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          '/${key.split('.').last}',
        );
        expect(
          find.descendant(
            of: find.byType(HomeWidget),
            matching: find.text('Circle two'),
          ),
          findsOneWidget,
        );
        expect(find.byType(AppBottomBar), findsOneWidget);
        expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      }
    });

    testWidgets('the add sheet offers only the areas the member may edit', (
      WidgetTester tester,
    ) async {
      home.response = Success(
        homeData(
          circles: const <CareCircleSummary>[
            CareCircleSummary(
              id: 'one',
              name: 'Circle one',
              canManageMeasurements: true,
              canManageAppointments: false,
            ),
          ],
        ),
      );
      await pumpApp(tester);

      await tester.tap(find.byTooltip('tab.add'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('add.measurement'.tr()), findsOneWidget);
      expect(find.text('add.medication'.tr()), findsNothing);
      expect(find.text('add.appointment'.tr()), findsNothing);
    });

    testWidgets('an admin opens the add sheet', (WidgetTester tester) async {
      home.response = Success(
        homeData(
          circles: const <CareCircleSummary>[
            CareCircleSummary(
              id: 'one',
              name: 'Circle one',
              canManageMedications: true,
            ),
          ],
        ),
      );
      await pumpApp(tester);

      // The empty Today page has its own add button with the same words, so
      // the sheet adds one more of them.
      final Finder addTitle = find.text('add.title'.tr());
      final int behindTheSheet = tester.widgetList(addTitle).length;

      await tester.tap(find.byTooltip('tab.add'.tr()));
      await tester.pumpAndSettle();

      expect(addTitle, findsNWidgets(behindTheSheet + 1));

      await tester.tap(find.text('add.medication'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('medications.add_title'.tr()), findsOneWidget);
      final save = find.text('medications.save_changes'.tr());
      await tester.tap(save);
      await tester.pump();
      expect(find.text('common.field_required'.tr()), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('no circles shows the empty state with a way to create one', (
      WidgetTester tester,
    ) async {
      home.response = Success(homeData(circles: <CareCircleSummary>[]));
      await pumpApp(tester);
      expect(find.text('home.no_circles'.tr()), findsOneWidget);
      // The button under the message; the switcher above has the same
      // words.
      expect(
        find.widgetWithText(FilledButton, 'home.create_circle'.tr()),
        findsOneWidget,
      );
      // With no circle yet, the switcher is the add button itself.
      final GlassCapsuleButton addCircle = tester.widget<GlassCapsuleButton>(
        find.descendant(
          of: find.byType(HomeWidget),
          matching: find.byType(GlassCapsuleButton),
        ),
      );
      expect(addCircle.label, 'topbar.add_circle'.tr());
      expect(addCircle.onPressed, isNotNull);
      final IconButton bell = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == 'topbar.notifications'.tr(),
        ),
      );
      // The bell works without a circle: an invitation or a request is how the
      // first circle can arrive. With nothing waiting there is no dot.
      expect(bell.onPressed, isNotNull);
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets(
      'account rises as a modal page and its close button returns to the shell',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await tester.tap(find.byTooltip('topbar.account'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.text('account.title'.tr()), findsOneWidget);
        expect(find.byType(AppBottomBar), findsNothing);
        // A modal: it rises from the bottom, and has ✕ in place of «رجوع».
        final PageRoute<dynamic> route =
            ModalRoute.of(tester.element(find.byType(AccountScreen)))!
                as PageRoute<dynamic>;
        expect(route.fullscreenDialog, isTrue);
        expect(find.text('common.back'.tr()), findsNothing);

        await tester.tap(find.byTooltip('common.close'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomBar), findsOneWidget);
      },
    );
  });
}
