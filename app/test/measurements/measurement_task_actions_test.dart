import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  setUpAll(initTestLocalization);

  testWidgets('«تسجيل قراءة» and «تخطي» are at least 48 tall', (tester) async {
    await pumpArabic(
      tester,
      home: Scaffold(
        body: MeasurementTaskActions(
          task: MeasurementOccurrence(
            planId: 'm-1',
            versionId: 'v-1',
            kind: MeasurementKind.glucose,
            scheduledOn: DateTime(2026, 11, 9),
            time: '12:00',
            deadlineAt: DateTime.utc(2026, 11, 9, 12),
            status: MeasurementStatus.due,
          ),
        ),
      ),
    );

    for (final String key in <String>[
      'measurements.record_reading',
      'measurements.skip',
    ]) {
      final Finder button = find.ancestor(
        of: find.text(key.tr()),
        matching: find.byWidgetPredicate((Widget w) => w is ButtonStyleButton),
      );
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(AppItemCard.touch),
      );
    }
  });
}
