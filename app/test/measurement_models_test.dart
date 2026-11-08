import 'package:app/features/measurements/domain/measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plan draft sends the entered target and Western date digits', () {
    final draft = MeasurementPlanDraft(
      kind: MeasurementKind.glucose,
      times: const [MeasurementTime(time: '07:30', glucoseContext: 'fasting')],
      weekdays: const [1, 3],
      startsOn: DateTime(2026, 11, 3),
      graceMinutes: 60,
      glucoseLow: 80,
      glucoseHigh: 140,
    );
    final json = draft.toJson();
    expect(json['starts_on'], '2026-11-03');
    // One reading time is sent as before, for a server without several.
    expect(json['time_of_day'], '07:30');
    expect(json['glucose_context'], 'fasting');
    expect(json.containsKey('times'), isFalse);
    expect(json['glucose_low'], 80);
    expect(json['glucose_high'], 140);
    expect(json.containsKey('expected_version_number'), isFalse);
    expect(draft.toJson(expectedVersion: 2)['expected_version_number'], 2);
    expect(draft.toJson(expectedVersion: 2)['effective_from_on'], '2026-11-03');
  });

  test('computed occurrence maps a late reading and its target result', () {
    final occurrence = MeasurementOccurrence.fromJson({
      'plan_id': 'plan',
      'version_id': 'version',
      'kind': 'glucose',
      'scheduled_on': '2026-11-03',
      'time_of_day': '07:30',
      'deadline_at': '2026-11-03T08:30:00+03:00',
      'status': 'read_late',
      'glucose_context': 'fasting',
      'record': {
        'id': 'record',
        'kind': 'glucose',
        'outcome': 'read',
        'recorded_at': '2026-11-03T09:00:00+03:00',
        'measured_at': '2026-11-03T08:45:00+03:00',
        'value_one': 151,
        'outside_target': true,
      },
    });
    expect(occurrence.status, MeasurementStatus.readLate);
    expect(occurrence.record?.outsideTarget, isTrue);
    expect(occurrence.record?.valueText, '151');
  });

  test('several reading times a day go as times, and come back', () {
    final draft = MeasurementPlanDraft(
      kind: MeasurementKind.glucose,
      times: const [
        MeasurementTime(time: '07:00', glucoseContext: 'fasting'),
        MeasurementTime(time: '14:00', glucoseContext: 'after_meal'),
      ],
      weekdays: const [1],
      startsOn: DateTime(2026, 11, 3),
      graceMinutes: 60,
      glucoseLow: 80,
      glucoseHigh: 140,
    );
    final json = draft.toJson();
    expect(json.containsKey('time_of_day'), isFalse);
    expect(json['times'], [
      {'time_of_day': '07:00', 'glucose_context': 'fasting'},
      {'time_of_day': '14:00', 'glucose_context': 'after_meal'},
    ]);

    final version = MeasurementVersion.fromJson({
      'id': 'v',
      'number': 1,
      'effective_from_on': '2026-11-03',
      'time_of_day': '07:00',
      'weekdays': [1],
      'grace_minutes': 60,
      'glucose_context': 'fasting',
      'times': json['times'],
    });
    expect(version.readingTimes, draft.times);

    // An older server lists no times: the one time it has.
    final older = MeasurementVersion.fromJson({
      'id': 'v',
      'number': 1,
      'effective_from_on': '2026-11-03',
      'time_of_day': '08:00',
      'weekdays': [1],
      'grace_minutes': 60,
      'glucose_context': 'before_meal',
    });
    expect(older.readingTimes, const [
      MeasurementTime(time: '08:00', glucoseContext: 'before_meal'),
    ]);
  });
}
