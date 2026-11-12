import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

DoseOccurrence _dose({DoseRecord? record}) => DoseOccurrence(
  planId: 'p-1',
  scheduleId: 's-1',
  name: 'ميتفورمين',
  scheduledOn: DateTime(2026, 11, 9),
  time: '09:00',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  record: record,
  missedAfterMinutes: 120,
);

void main() {
  setUpAll(initTestLocalization);

  testWidgets('a dose nobody recorded after its window is yellow', (
    tester,
  ) async {
    late DoseRowStatus status;
    await pumpArabic(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          // The patient's wall time is on the UTC scale: noon is three hours
          // after 09:00, with a two-hour window.
          status = DoseRowStatus.of(
            context,
            _dose(),
            DateTime.utc(2026, 11, 9, 12),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(status.unrecorded, isTrue);
    expect(status.tone, StatusTone.attention);
  });

  testWidgets('an upcoming dose is ahead and not unrecorded', (tester) async {
    late DoseRowStatus status;
    await pumpArabic(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          status = DoseRowStatus.of(
            context,
            _dose(),
            DateTime.utc(2026, 11, 9, 7),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(status.unrecorded, isFalse);
    expect(status.tone, StatusTone.info);
  });
}
