import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/home/domain/overdue_tasks.dart';
import 'package:app/features/measurements/domain/measurement.dart';
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
}) => CareAppointment(
  id: 'a-$day',
  specialty: 'عيادة السكري',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, day),
  time: '16:30',
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
