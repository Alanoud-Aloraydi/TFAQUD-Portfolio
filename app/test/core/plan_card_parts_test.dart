import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  group('PlanCardParts', () {
    setUpAll(initTestLocalization);

    testWidgets('the details line: the date on the right, then the label, '
        'and the arrow on the far left', (WidgetTester tester) async {
      int taps = 0;
      await pumpArabic(
        tester,
        home: Scaffold(
          body: PlanDetailsToggle(
            start: 'بدأ في 7 نوفمبر 2026',
            label: 'تفاصيل الدواء',
            expanded: false,
            onTap: () => taps++,
          ),
        ),
      );

      final double date = tester
          .getCenter(find.text('بدأ في 7 نوفمبر 2026'))
          .dx;
      final double label = tester.getCenter(find.text('تفاصيل الدواء')).dx;
      final double arrow = tester
          .getCenter(find.byIcon(CupertinoIcons.chevron_down))
          .dx;
      expect(date, greaterThan(label));
      expect(label, greaterThan(arrow));

      await tester.tap(find.text('تفاصيل الدواء'));
      expect(taps, 1);
    });

    testWidgets('a plan that started says «بدأ», one to come «يبدأ»', (
      WidgetTester tester,
    ) async {
      late BuildContext captured;
      await pumpArabic(
        tester,
        home: Builder(
          builder: (BuildContext context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      );
      final DateTime start = DateTime(2026, 11, 7);
      final String date = formatMedicationDate(captured, start);

      expect(
        formatStartDate(captured, start, today: DateTime(2026, 11, 11)),
        'medications.started_on'.tr(args: <String>[date]),
      );
      expect(
        formatStartDate(captured, start, today: DateTime(2026, 11, 7)),
        'medications.started_on'.tr(args: <String>[date]),
      );
      expect(
        formatStartDate(captured, start, today: DateTime(2026, 11, 6)),
        'medications.starts_on'.tr(args: <String>[date]),
      );
      expect(
        formatMedicationPeriod(
          captured,
          start,
          null,
          today: DateTime(2026, 11, 11),
        ),
        'بدأ في $date',
      );
    });
  });
}
