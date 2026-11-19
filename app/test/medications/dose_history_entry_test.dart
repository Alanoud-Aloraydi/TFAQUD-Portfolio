import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/entities/medication_version.dart';
import 'package:flutter_test/flutter_test.dart';

final PatientClock _riyadh = PatientClock('Asia/Riyadh');

final MedicationVersion _medicine = MedicationVersion(
  number: 1,
  name: 'ميتفورمين',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  startsOn: DateTime(2026, 11),
  effectiveFromOn: DateTime(2026, 11),
  schedules: const <MedicationSchedule>[],
);

DoseOccurrence _at(DateTime day, String time) => DoseOccurrence(
  planId: 'p-1',
  scheduleId: 's-1',
  name: 'ميتفورمين',
  scheduledOn: day,
  time: time,
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  missedAfterMinutes: 120,
);

/// Taken at [hour] UTC: three hours later in Riyadh.
ExtraDose _extra(DateTime day, int hour) => ExtraDose(
  id: 'e-$hour',
  planId: 'p-1',
  takenAt: DateTime.utc(day.year, day.month, day.day, hour),
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
  recordedByAccountId: 'a-1',
  recordedByName: 'لينا',
);

void main() {
  final DateTime ninth = DateTime(2026, 11, 9);
  final DateTime tenth = DateTime(2026, 11, 10);

  test('extra doses sit among the doses by the time they were taken', () {
    final List<DoseHistoryEntry> entries = doseHistoryEntries(
      _riyadh,
      doses: <DoseOccurrence>[_at(ninth, '08:00'), _at(ninth, '20:00')],
      // 13:00 and, the next day, 03:00 on the patient's clock.
      extras: <ExtraDose>[_extra(ninth, 10), _extra(tenth, 0)],
      medicine: _medicine,
    );

    expect(
      entries.map(
        (entry) => switch (entry) {
          ScheduledDoseEntry(:final occurrence) => occurrence.time,
          ExtraDoseEntry(:final at) => 'extra ${at.hour}',
        },
      ),
      <String>['extra 3', '20:00', 'extra 13', '08:00'],
    );
    expect(entries.first.day, tenth);
    expect(entries.first.recorder, ('a-1', 'لينا'));
  });

  test('only the days already read: «أقدم» brings the older ones', () {
    final List<DoseHistoryEntry> entries = doseHistoryEntries(
      _riyadh,
      doses: <DoseOccurrence>[_at(tenth, '08:00')],
      extras: <ExtraDose>[_extra(ninth, 10), _extra(tenth, 10)],
      medicine: _medicine,
      from: tenth,
    );

    expect(entries.map((entry) => entry.day), <DateTime>[tenth, tenth]);
  });
}
