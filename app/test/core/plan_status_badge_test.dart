import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  setUpAll(initTestLocalization);

  group('PlanStatusBadge', () {
    test('each status has its own tone and its own fill', () {
      final Set<StatusTone> tones = <StatusTone>{
        for (final PlanStatus status in PlanStatus.values)
          PlanStatusBadge.tone(status),
      };
      expect(tones.length, PlanStatus.values.length);
      expect(
        tones.map(StatusBadge.fill).toSet().length,
        PlanStatus.values.length,
      );
    });

    testWidgets('shows the translated label of every status', (tester) async {
      for (final PlanStatus status in PlanStatus.values) {
        await pumpArabic(tester, home: Scaffold(body: PlanStatusBadge(status)));
        expect(find.text('plan_status.${status.name}'.tr()), findsOneWidget);
      }
    });

    testWidgets('is the shared status badge in the tone of the status', (
      tester,
    ) async {
      await pumpArabic(
        tester,
        home: const Scaffold(body: PlanStatusBadge(PlanStatus.stopped)),
      );

      final StatusBadge badge = tester.widget(find.byType(StatusBadge));
      expect(badge.tone, StatusTone.muted);
    });
  });

  group('StatusBadge', () {
    testWidgets('every tone keeps its words readable on its fill', (
      tester,
    ) async {
      late BuildContext context;
      await pumpArabic(
        tester,
        home: Builder(
          builder: (BuildContext found) {
            context = found;
            return const SizedBox.shrink();
          },
        ),
      );

      for (final StatusTone tone in StatusTone.values) {
        if (tone == StatusTone.onDark) continue;
        final double fill = StatusBadge.fill(tone).computeLuminance();
        final double ink = StatusBadge.ink(context, tone).computeLuminance();
        expect(
          (fill + 0.05) / (ink + 0.05),
          greaterThan(4.5),
          reason: tone.name,
        );
      }
    });
  });
}
