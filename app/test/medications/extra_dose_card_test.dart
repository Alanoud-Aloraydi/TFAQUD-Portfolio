import 'package:app/core/media/person_photo.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/entities/medication_version.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  setUpAll(initTestLocalization);

  testWidgets('an extra dose reads as the others, with «إضافية» in the '
      'corner where they say what became of them', (tester) async {
    final ExtraDose dose = ExtraDose(
      id: 'e-1',
      planId: 'p-1',
      // 16:48 in Riyadh.
      takenAt: DateTime.utc(2026, 11, 19, 13, 48),
      doseValue: 1,
      doseUnit: DoseUnit.tablet,
      recordedByAccountId: 'a-1',
      recordedByName: 'العنود',
    );
    final MedicationVersion medicine = MedicationVersion(
      number: 1,
      name: 'ميتفورمين',
      strengthValue: 500,
      strengthUnit: StrengthUnit.milligram,
      dosageForm: DosageForm.tablet,
      startsOn: DateTime(2026, 11),
      effectiveFromOn: DateTime(2026, 11),
      schedules: const <MedicationSchedule>[],
    );
    await pumpArabic(
      tester,
      clock: PatientClock('Asia/Riyadh'),
      home: Scaffold(
        body: ExtraDoseCard(
          entry: ExtraDoseEntry(
            dose,
            medicine,
            at: DateTime.utc(2026, 11, 19, 16, 48),
          ),
          circleId: 'c-1',
        ),
      ),
    );

    expect(find.textContaining('4:48'), findsOneWidget);
    expect(find.text('ميتفورمين'), findsOneWidget);
    expect(find.text('medications.extra_dose_badge'.tr()), findsOneWidget);
    expect(find.text('العنود'), findsOneWidget);
    expect(find.byType(PersonPhoto), findsOneWidget);
  });
}
