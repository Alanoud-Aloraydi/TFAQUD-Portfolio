import 'package:app/features/medications/domain/dose_retention.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 11, 19);

// 90 days before: the first day still kept; the warning reaches 4 more.
final DateTime _firstKept = DateTime(2026, 8, 21);
final DateTime _lastWarned = DateTime(2026, 8, 25);

MedicationPlan _plan(
  DateTime startsOn, {
  DateTime? endsOn,
  DateTime? stoppedAt,
}) => MedicationPlan(
  id: 'plan',
  createdAt: DateTime.utc(2026, 1, 1),
  discontinuedAt: stoppedAt,
  version: MedicationVersion(
    number: 1,
    name: 'Medicine',
    strengthValue: 5,
    strengthUnit: StrengthUnit.milligram,
    dosageForm: DosageForm.tablet,
    startsOn: startsOn,
    endsOn: endsOn,
    effectiveFromOn: startsOn,
    schedules: const <MedicationSchedule>[],
  ),
);

void main() {
  group('DoseRetention', () {
    test('keeps 90 days of doses', () {
      expect(DoseRetention.firstKeptDay(_today), _firstKept);
    });

    test('warns of the next five days when a medicine was taken', () {
      final MedicationPlan plan = _plan(DateTime(2026, 5, 1));

      expect(DoseRetention.goingThrough(_today, [plan], null), _lastWarned);
    });

    test('says nothing when no medicine was taken in those days', () {
      final MedicationPlan later = _plan(DateTime(2026, 9, 1));
      final MedicationPlan ended = _plan(
        DateTime(2026, 5, 1),
        endsOn: DateTime(2026, 8, 20),
      );
      final MedicationPlan stopped = _plan(
        DateTime(2026, 5, 1),
        stoppedAt: DateTime(2026, 8, 1, 12),
      );

      for (final MedicationPlan plan in [later, ended, stopped]) {
        expect(DoseRetention.goingThrough(_today, [plan], null), isNull);
      }
      expect(DoseRetention.goingThrough(_today, [], null), isNull);
    });

    test('«لاحقًا» waits five days, and an export until today', () {
      final MedicationPlan plan = _plan(DateTime(2026, 5, 1));
      final DateTime later = DoseRetention.laterThrough(_lastWarned);
      DateTime? on(int days, DateTime settled) => DoseRetention.goingThrough(
        DateTime(2026, 11, 19 + days),
        [plan],
        settled,
      );

      for (var days = 0; days < 5; days++) {
        expect(on(days, later), isNull);
      }
      expect(on(5, later), DateTime(2026, 8, 30));
      expect(on(86, _today), isNull);
      expect(on(87, _today), DateTime(2026, 11, 20));
    });
  });
}
