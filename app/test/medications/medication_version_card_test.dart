import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/widgets/medication_pending_revision.dart';
import 'package:app/features/medications/presentation/widgets/medication_revision_history.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_row.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

MedicationSchedule _at(String time, {int? every}) => MedicationSchedule(
  id: 's-$time',
  time: time,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  weekdays: const <int>[],
  repeat: ScheduleRepeat.interval,
  intervalDays: every ?? 1,
);

MedicationVersion _version(int number, DateTime from, String time) =>
    MedicationVersion(
      number: number,
      name: 'أسبرين',
      strengthValue: 81,
      strengthUnit: StrengthUnit.milligram,
      dosageForm: DosageForm.tablet,
      startsOn: DateTime(2026, 11, 9),
      effectiveFromOn: from,
      reason: 'حماية القلب',
      schedules: <MedicationSchedule>[_at(time)],
    );

final MedicationVersion _first = _version(1, DateTime(2026, 11, 9), '08:00');

/// Aspirin since 9 November, with a change to 9:00 waiting for the 18th.
final MedicationPlan _plan = MedicationPlan(
  id: 'p-1',
  createdAt: DateTime.utc(2026, 11, 9),
  version: _first,
  history: <MedicationVersion>[_first],
  pendingVersion: _version(2, DateTime(2026, 11, 18), '09:00'),
);

void main() {
  setUpAll(initTestLocalization);

  group('The medicine page', () {
    testWidgets('a dose time reads as pills on one line', (tester) async {
      await pumpArabic(
        tester,
        home: Scaffold(
          body: MedicationScheduleRow(schedule: _at('08:00', every: 2)),
        ),
      );

      // «8:00 ص»، «1 حبة»، «كل يومين».
      final Finder pills = find.byType(FactPill);
      expect(pills, findsNWidgets(3));
      for (int i = 1; i < 3; i++) {
        expect(
          tester.getCenter(pills.at(i)).dy,
          tester.getCenter(pills.first).dy,
        );
      }
    });

    testWidgets('a waiting change is the same card as «بداية الخطة», with '
        'the same labelled lines', (tester) async {
      await pumpArabic(
        tester,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                MedicationRevisionHistory(plan: _plan),
                MedicationPendingRevision(
                  plan: _plan,
                  circleId: 'c-1',
                  canManage: true,
                  onCancel: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MedicationVersionCard), findsNWidgets(2));
      for (final String label in <String>[
        'medications.medicine_label',
        'medications.dose_schedules',
        'medications.reason',
        'medications.missed_after',
      ]) {
        expect(find.text(label.tr()), findsNWidgets(2));
      }
      // The waiting change shows the time of now crossed out above its own.
      final Text crossed = tester.widget(find.textContaining('8:00').last);
      expect(crossed.style?.decoration, TextDecoration.lineThrough);
      expect(find.text('medications.cancel_pending'.tr()), findsOneWidget);
    });
  });
}
