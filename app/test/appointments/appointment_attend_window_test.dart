import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

CareAppointment _visit(
  int day, {
  AppointmentStatus status = AppointmentStatus.scheduled,
}) => CareAppointment(
  id: 'v',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, day),
  time: '10:00',
  place: null,
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: status,
  updatedAt: DateTime.utc(2026, 11, 1),
);

/// [hour]:[minute] on 9 November, as the patient clock tells it.
DateTime _wall(int hour, int minute) =>
    wallClockAt(DateTime(2026, 11, 9), '$hour:$minute');

void main() {
  group('«حضرت» on a visit', () {
    final DateTime today = DateTime(2026, 11, 9);

    test('opens an hour before its time, not earlier', () {
      final CareAppointment visit = _visit(9);

      // Wall times, on the scale of the patient clock (UTC fields).
      expect(visit.canAttendAt(_wall(8, 59), today), isFalse);
      expect(visit.canAttendAt(_wall(9, 0), today), isTrue);
      expect(visit.canAttendAt(_wall(23, 0), today), isTrue);
    });

    test('stays open while «يحتاج انتباهك» lists it, then it is missed', () {
      final DateTime now = _wall(12, 0);

      expect(_visit(7).canAttendAt(now, today), isTrue);
      expect(_visit(7).isMissedOn(today), isFalse);
      expect(_visit(6).canAttendAt(now, today), isFalse);
      expect(_visit(6).isMissedOn(today), isTrue);
    });

    test('a closed visit is neither open nor missed', () {
      final DateTime now = _wall(12, 0);
      for (final AppointmentStatus status in <AppointmentStatus>[
        AppointmentStatus.completed,
        AppointmentStatus.cancelled,
      ]) {
        expect(_visit(6, status: status).isMissedOn(today), isFalse);
        expect(_visit(9, status: status).canAttendAt(now, today), isFalse);
      }
    });
  });
}
