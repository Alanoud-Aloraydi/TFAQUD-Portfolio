import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
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

  group('nearestTask visits', () {
    CareAppointment visit(int day, String time) => CareAppointment(
      id: 'v-$day-$time',
      kind: AppointmentKind.dialysis,
      otherKind: null,
      scheduledOn: DateTime(2026, 11, day),
      time: time,
      place: null,
      remoteMethod: null,
      companions: const <AppointmentCompanion>[],
      status: AppointmentStatus.scheduled,
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    NextTask? next(
      DateTime now,
      List<CareAppointment> visits, [
      List<MeasurementOccurrence> tasks = const [],
    ]) => nearestTask(now, const [], tasks, visits);

    test('a visit of tomorrow is not on today\'s card', () {
      final List<CareAppointment> tomorrow = [visit(20, '12:00')];

      expect(next(DateTime.utc(2026, 11, 19, 12), tomorrow), isNull);
    });

    test('on its day it is the next task before its time', () {
      final NextTask? task = next(DateTime.utc(2026, 11, 20, 9), [
        visit(20, '12:00'),
      ]);

      expect(task?.appointment?.id, 'v-20-12:00');
    });

    test('past its time it stays until another task of the day comes', () {
      final List<MeasurementOccurrence> later = [
        _task(day: 20, time: '13:00', status: MeasurementStatus.upcoming),
      ];
      final List<CareAppointment> visits = [visit(20, '12:00')];

      expect(
        next(DateTime.utc(2026, 11, 20, 12, 40), visits, later)?.appointment,
        isNotNull,
      );
      // At 13:00 the reading comes after it: the visit leaves the card.
      expect(
        next(DateTime.utc(2026, 11, 20, 13), visits, later)?.appointment,
        isNull,
      );
    });
  });
}
