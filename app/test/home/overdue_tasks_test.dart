import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/home/domain/overdue_tasks.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 11, 11);

MeasurementOccurrence _task(
  int day, {
  MeasurementStatus status = MeasurementStatus.missed,
}) => MeasurementOccurrence(
  planId: 'm-1',
  versionId: 'v-1',
  kind: MeasurementKind.glucose,
  scheduledOn: DateTime(2026, 11, day),
  time: '08:00',
  deadlineAt: DateTime.utc(2026, 11, day, 6),
  status: status,
);

CareAppointment _visit(
  int day, {
  AppointmentStatus status = AppointmentStatus.scheduled,
  String time = '16:30',
}) => CareAppointment(
  id: 'a-$day-$time',
  specialty: 'عيادة السكري',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, day),
  time: time,
  place: null,
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: status,
  updatedAt: DateTime.utc(2026, 11),
);

void main() {
  group('OverdueTasks.measurements', () {
    test('keeps missed tasks from two days back through today', () {
      final result = OverdueTasks.measurements([
        _task(8),
        _task(9),
        _task(10),
        _task(11),
      ], _today);

      expect(result.map((task) => task.scheduledOn.day), [9, 10, 11]);
    });

    test('leaves out tasks that are not missed or are from tomorrow', () {
      final result = OverdueTasks.measurements([
        _task(10, status: MeasurementStatus.read),
        _task(10, status: MeasurementStatus.skipped),
        _task(10, status: MeasurementStatus.readLate),
        _task(12),
      ], _today);

      expect(result, isEmpty);
    });
  });

  group('OverdueTasks.appointments', () {
    test('keeps open appointments of the two days before today', () {
      final result = OverdueTasks.appointments([
        _visit(8),
        _visit(9),
        _visit(10),
      ], _today);

      // «يحتاج انتباهك» reads from the oldest to the newest.
      expect(result.map((item) => item.scheduledOn.day), [9, 10]);
    });

    test('today\'s waits there once another task came after it', () {
      final List<CareAppointment> visits = [_visit(11)];
      final DateTime visitAt = visits.single.scheduledAt;

      // Nothing after it yet: it stays on the top card.
      expect(
        OverdueTasks.appointments(
          visits,
          _today,
          now: visitAt.add(const Duration(hours: 1)),
        ),
        isEmpty,
      );
      // Another visit of the day came after it.
      final List<CareAppointment> two = [...visits, _visit(11, time: '23:00')];
      expect(
        OverdueTasks.appointments(
          two,
          _today,
          now: visitAt.add(const Duration(hours: 7)),
        ).map((item) => item.time),
        [visits.single.time],
      );
    });

    test('leaves today to the schedule and closed ones out', () {
      final result = OverdueTasks.appointments([
        _visit(11),
        _visit(10, status: AppointmentStatus.completed),
        _visit(10, status: AppointmentStatus.cancelled),
      ], _today);

      expect(result, isEmpty);
    });
  });
}
