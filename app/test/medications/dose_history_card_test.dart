import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// A 09:00 dose of 9 November 2026 with [record].
DoseOccurrence _dose(DoseRecord record) => DoseOccurrence(
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

/// Taken at 9:40 in Riyadh, recorded by لينا.
final DoseRecord _taken = DoseRecord(
  id: 'r-1',
  outcome: DoseOutcome.taken,
  takenAt: DateTime.utc(2026, 11, 9, 6, 40),
  recordedAt: DateTime.utc(2026, 11, 9, 6, 41),
  recordedByAccountId: 'a-1',
  recordedByName: 'لينا',
);

Future<void> _show(WidgetTester tester, DoseRecord record) => pumpArabic(
  tester,
  home: Scaffold(
    body: DoseOccurrenceCard(occurrence: _dose(record), circleId: 'c-1'),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('A dose of «سجل الجرعات»', () {
    testWidgets('taken: the time it really was, «تم أخذها» in the corner '
        'with who recorded it under it, and no box under the dose', (
      tester,
    ) async {
      // 9:40: forty minutes after its time.
      await _show(tester, _taken);

      expect(find.textContaining('9:40'), findsOneWidget);
      expect(find.textContaining('9:00'), findsNothing);
      final Finder pill = find.text('today_dashboard.status.taken'.tr());
      expect(pill, findsOneWidget);
      expect(find.text('لينا'), findsOneWidget);
      expect(find.byType(PersonPhoto), findsOneWidget);
      expect(find.byType(DoseRecordedStatus), findsNothing);
      // The person is under the pill, on the same side.
      expect(
        tester.getTopLeft(find.text('لينا')).dy,
        greaterThan(tester.getBottomLeft(pill).dy - 1),
      );
      expect(
        tester.getTopLeft(find.byType(PersonPhoto)).dx,
        lessThan(tester.getCenter(find.text('ميتفورمين')).dx),
      );
    });

    testWidgets('the strength and dose are pills on the name\'s line, the '
        'time right above it, the person bigger and centred under the pill', (
      tester,
    ) async {
      await _show(tester, _taken);
      // The test font draws every letter a full square, so the name and
      // its pills need a wider line than a phone's to fit on one; on a
      // narrow one the pills move under the name instead.
      tester.view.physicalSize = const Size(800, 900);
      await tester.pumpAndSettle();

      final Finder name = find.text('ميتفورمين');
      final Finder strength = find.textContaining('500');
      final Finder dose = find.textContaining('medications.unit.tablet'.tr());
      for (final Finder fact in <Finder>[strength, dose]) {
        expect(fact, findsOneWidget);
        expect(
          (tester.getCenter(fact).dy - tester.getCenter(name).dy).abs(),
          lessThan(4),
        );
      }
      // No room left between the time and the medicine.
      expect(
        tester.getTopLeft(name).dy -
            tester.getBottomLeft(find.textContaining('9:40')).dy,
        lessThan(8),
      );
      expect(
        tester.getCenter(find.byType(RecorderLine)).dx,
        moreOrLessEquals(tester.getCenter(find.byType(StatusBadge)).dx),
      );
      expect(tester.getSize(find.byType(PersonPhoto)).width, AppSizes.icon);
    });

    testWidgets('skipped: «تم تخطيها» and why, at its own time', (
      tester,
    ) async {
      await _show(
        tester,
        DoseRecord(
          id: 'r-2',
          outcome: DoseOutcome.skipped,
          skipReasonCode: 'side_effects',
          recordedAt: DateTime.utc(2026, 11, 9, 7),
          recordedByAccountId: 'a-2',
          recordedByName: 'خالد',
        ),
      );

      expect(find.textContaining('9:00'), findsOneWidget);
      expect(find.text('today_dashboard.status.skipped'.tr()), findsOneWidget);
      expect(
        find.textContaining('medications.skip_reason.sideEffects'.tr()),
        findsOneWidget,
      );
      expect(find.text('خالد'), findsOneWidget);
    });
  });
}
