import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:flutter_test/flutter_test.dart';

MeasurementOccurrence _task({
  required int day,
  String time = '08:00',
  MeasurementStatus status = MeasurementStatus.due,
  int deadlineHour = 10,
  MeasurementReading? record,
}) => MeasurementOccurrence(
  planId: 'm-1',
  versionId: 'v-1',
  kind: MeasurementKind.glucose,
  scheduledOn: DateTime(2026, 11, day),
  time: time,
  deadlineAt: DateTime.utc(2026, 11, day, deadlineHour),
  status: status,
  record: record,
);

NextTask? _next(DateTime now, List<MeasurementOccurrence> tasks) =>
    nearestTask(now, const [], tasks, const <CareAppointment>[]);

void main() {
  group('nearestTask measurements', () {
    test('one still to come is the next task', () {
      final NextTask? next = _next(DateTime.utc(2026, 11, 11, 7), [
        _task(day: 11, status: MeasurementStatus.upcoming),
      ]);
      expect(next?.measurement?.planId, 'm-1');
      expect(next?.at, DateTime.utc(2026, 11, 11, 8));
    });

    test('one whose time passed today still shows, counted from now', () {
      final DateTime now = DateTime.utc(2026, 11, 11, 9);
      final NextTask? next = _next(now, [_task(day: 11)]);
      expect(next?.measurement, isNotNull, reason: 'it was invisible before');
      expect(next?.at, now);
    });

    test('one past its deadline is left to «يحتاج انتباهك»', () {
      final NextTask? next = _next(DateTime.utc(2026, 11, 11, 11), [
        _task(day: 11),
      ]);
      expect(next, isNull);
    });

    test('an earlier day is not answered on today\'s card', () {
      final NextTask? next = _next(DateTime.utc(2026, 11, 11, 9), [
        _task(day: 10, deadlineHour: 23),
      ]);
      expect(next, isNull);
    });

    test('a recorded one is not a task', () {
      final NextTask? next = _next(DateTime.utc(2026, 11, 11, 9), [
        _task(
          day: 11,
          record: MeasurementReading(
            id: 'r-1',
            kind: MeasurementKind.glucose,
            outcome: 'read',
            recordedAt: DateTime.utc(2026, 11, 11, 8),
            valueOne: 100,
          ),
        ),
      ]);
      expect(next, isNull);
    });
  });
}
