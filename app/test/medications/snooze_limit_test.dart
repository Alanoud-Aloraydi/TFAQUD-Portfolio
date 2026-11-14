import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:flutter_test/flutter_test.dart';

DoseOccurrence _dose(String plan, int day, String time) => DoseOccurrence(
  planId: plan,
  scheduleId: 's-$plan-$time',
  scheduledOn: DateTime(2026, 11, day),
  time: time,
  name: 'ميتفورمين',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

void main() {
  /// 08:00 on 12 November in Riyadh.
  final DateTime eight = DateTime.utc(2026, 11, 12, 5);

  group('snoozeLimit', () {
    test('is 12 hours when no other dose is near', () {
      expect(snoozeLimit(now: eight, dose: eight), const Duration(hours: 12));
      expect(
        snoozeLimit(
          now: eight,
          dose: eight,
          nextDose: eight.add(const Duration(hours: 30)),
        ),
        const Duration(hours: 12),
      );
    });

    test('stops halfway to the next dose of the same medicine', () {
      // Doses 6 hours apart: 3 hours at most, from the dose's time.
      expect(
        snoozeLimit(
          now: eight,
          dose: eight,
          nextDose: eight.add(const Duration(hours: 6)),
        ),
        const Duration(hours: 3),
      );
      // Already an hour late: 2 hours are left.
      expect(
        snoozeLimit(
          now: eight.add(const Duration(hours: 1)),
          dose: eight,
          nextDose: eight.add(const Duration(hours: 6)),
        ),
        const Duration(hours: 2),
      );
    });

    test('goes in whole steps of 5 minutes, and never below zero', () {
      expect(
        snoozeLimit(
          now: eight,
          dose: eight,
          nextDose: eight.add(const Duration(minutes: 47)),
        ),
        const Duration(minutes: 20),
      );
      expect(
        snoozeLimit(
          now: eight.add(const Duration(hours: 4)),
          dose: eight,
          nextDose: eight.add(const Duration(hours: 6)),
        ),
        Duration.zero,
      );
    });
  });

  test('the next dose is the same medicine\'s, even on the next day', () {
    final PatientClock clock = PatientClock('Asia/Riyadh');
    final DoseOccurrence night = _dose('a', 12, '22:00');
    final List<DoseOccurrence> doses = <DoseOccurrence>[
      _dose('a', 12, '08:00'),
      night,
      _dose('b', 12, '23:00'),
      _dose('a', 13, '06:00'),
    ];

    expect(
      nextDoseOf(night, doses, clock),
      clock.momentOf(DateTime(2026, 11, 13), '06:00'),
    );
    // 22:00 to 06:00 is 8 hours: 4 at most, from 22:00.
    expect(
      doseSnoozeLimit(
        night,
        doses,
        clock,
        clock.momentOf(DateTime(2026, 11, 12), '22:00'),
      ),
      const Duration(hours: 4),
    );
  });
}
