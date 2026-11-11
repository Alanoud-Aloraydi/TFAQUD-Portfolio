import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _task({
  String kind = 'blood_pressure',
  String status = 'read_late',
}) => <String, dynamic>{
  'plan_id': 'plan-1',
  'plan_version_id': 'version-1',
  'measurement_state': null,
  'kind': kind,
  'scheduled_on': '2026-11-03',
  'time_of_day': '08:00',
  'deadline_at': '2026-11-03T06:00:00+00:00',
  'status': status,
};

void main() {
  group('MeasurementModels', () {
    test('plan draft sends the entered target and Western date digits', () {
      final draft = MeasurementPlanDraft(
        kind: MeasurementKind.glucose,
        times: const [
          MeasurementTime(time: '07:30', measurementState: 'fasting'),
        ],
        weekdays: const [1, 3],
        startsOn: DateTime(2026, 11, 3),
        missedAfterMinutes: 60,
        glucoseLow: 80,
        glucoseHigh: 140,
      );
      final json = draft.toJson();
      expect(json['starts_on'], '2026-11-03');
      expect(json['times'], [
        {'time_of_day': '07:30', 'measurement_state': 'fasting'},
      ]);
      expect(json['missed_after_minutes'], 60);
      expect(json['glucose_low'], 80);
      expect(json['glucose_high'], 140);
      expect(json.containsKey('expected_version_number'), isFalse);
      expect(draft.toJson(expectedVersion: 2)['expected_version_number'], 2);
      expect(
        draft.toJson(expectedVersion: 2)['effective_from_on'],
        '2026-11-03',
      );
    });

    test('computed occurrence maps a late reading and its target result', () {
      final occurrence = MeasurementOccurrence.fromJson({
        'plan_id': 'plan',
        'plan_version_id': 'version',
        'kind': 'glucose',
        'scheduled_on': '2026-11-03',
        'time_of_day': '07:30',
        'deadline_at': '2026-11-03T08:30:00+03:00',
        'status': 'read_late',
        'measurement_state': 'fasting',
        'reading': {
          'id': 'record',
          'kind': 'glucose',
          'outcome': 'read',
          'recorded_at': '2026-11-03T09:00:00+03:00',
          'measured_at': '2026-11-03T08:45:00+03:00',
          'glucose_value': 151,
          'conditions': ['fasting'],
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
          MeasurementTime(time: '07:00', measurementState: 'fasting'),
          MeasurementTime(time: '14:00', measurementState: 'after_meal'),
        ],
        weekdays: const [1],
        startsOn: DateTime(2026, 11, 3),
        missedAfterMinutes: 60,
        glucoseLow: 80,
        glucoseHigh: 140,
      );
      final json = draft.toJson();
      expect(json.containsKey('time_of_day'), isFalse);
      expect(json['times'], [
        {'time_of_day': '07:00', 'measurement_state': 'fasting'},
        {'time_of_day': '14:00', 'measurement_state': 'after_meal'},
      ]);

      final version = MeasurementVersion.fromJson({
        'id': 'v',
        'version_number': 1,
        'effective_from_on': '2026-11-03',
        'weekdays': [1],
        'missed_after_minutes': 60,
        'times': json['times'],
      });
      expect(version.readingTimes, draft.times);
    });

    test('a blood-pressure time has no measurement state', () {
      final draft = MeasurementPlanDraft(
        kind: MeasurementKind.bp,
        times: const [MeasurementTime(time: '08:00')],
        weekdays: const [1],
        startsOn: DateTime(2026, 11, 3),
        missedAfterMinutes: 60,
        systolicLimit: 130,
        diastolicLimit: 80,
      );
      final json = draft.toJson();
      expect(json.containsKey('time_of_day'), isFalse);
      expect(json['times'], [
        {'time_of_day': '08:00', 'measurement_state': null},
      ]);
    });

    test('a reading sends its values and all its conditions', () {
      const draft = MeasurementReadingDraft(
        kind: MeasurementKind.glucose,
        outcome: 'read',
        valueOne: 150,
        conditions: ['after_meal', 'stress', 'exertion'],
      );
      final json = draft.toJson();
      expect(json['glucose_value'], 150);
      expect(json['conditions'], ['after_meal', 'stress', 'exertion']);

      const pressure = MeasurementReadingDraft(
        kind: MeasurementKind.bp,
        outcome: 'read',
        valueOne: 130,
        valueTwo: 80,
        conditions: [],
      );
      expect(pressure.toJson()['kind'], 'blood_pressure');
      expect(pressure.toJson()['systolic_value'], 130);
      expect(pressure.toJson()['diastolic_value'], 80);
    });

    test('a meal state replaces another; other conditions add up', () {
      var selected = MeasurementConditions.toggle(const [], 'fasting');
      selected = MeasurementConditions.toggle(selected, 'exertion');
      selected = MeasurementConditions.toggle(selected, 'after_meal');
      expect(selected, ['exertion', 'after_meal']);
      expect(MeasurementConditions.toggle(selected, 'exertion'), [
        'after_meal',
      ]);
    });

    test('«أخرى» sends its words, and only with «أخرى»', () {
      const other = MeasurementReadingDraft(
        kind: MeasurementKind.bp,
        outcome: 'read',
        conditions: ['other'],
        otherCondition: 'بعد القهوة',
      );
      expect(other.toJson()['other_text'], 'بعد القهوة');

      const without = MeasurementReadingDraft(
        kind: MeasurementKind.bp,
        outcome: 'read',
        conditions: ['stress'],
        otherCondition: 'بعد القهوة',
      );
      expect(without.toJson().containsKey('other_text'), isFalse);

      final reading = MeasurementReading.fromJson({
        'id': 'r',
        'kind': 'blood_pressure',
        'outcome': 'read',
        'recorded_at': '2026-11-09T10:00:00+03:00',
        'conditions': ['other'],
        'other_text': 'بعد القهوة',
      });
      expect(reading.otherCondition, 'بعد القهوة');
    });
  });

  group('MeasurementParsing', () {
    test('an unknown kind or status leaves out that item only', () {
      final List<MeasurementOccurrence> tasks = knownMeasurementItems(<dynamic>[
        _task(),
        _task(kind: 'weight'),
        _task(status: 'paused'),
      ], MeasurementOccurrence.fromJson);

      expect(tasks, hasLength(1));
      expect(tasks.single.status, MeasurementStatus.readLate);
    });

    group('latestReadingMoment', () {
      // 00:10 on 4 November in Riyadh (UTC+3).
      final PatientClock clock = PatientClock(
        'Asia/Riyadh',
        clock: () => DateTime.utc(2026, 11, 3, 21, 10),
      );

      test('a time still to come today is last night', () {
        expect(
          latestReadingMoment(clock, '23:50'),
          clock.momentOf(DateTime(2026, 11, 3), '23:50'),
        );
      });

      test('a time already past today is today', () {
        expect(
          latestReadingMoment(clock, '00:05'),
          clock.momentOf(DateTime(2026, 11, 4), '00:05'),
        );
      });
    });
  });
}
