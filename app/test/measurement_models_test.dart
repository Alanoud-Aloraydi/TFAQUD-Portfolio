import 'package:app/features/measurements/domain/measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plan draft sends the entered target and Western date digits', () {
    final draft = MeasurementPlanDraft(
      kind: MeasurementKind.glucose,
      time: '07:30',
      weekdays: const [1, 3],
      startsOn: DateTime(2026, 11, 3),
      graceMinutes: 60,
      glucoseContext: 'fasting',
      glucoseLow: 80,
      glucoseHigh: 140,
    );
    final json = draft.toJson();
    expect(json['starts_on'], '2026-11-03');
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
}
