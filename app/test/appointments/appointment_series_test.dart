import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

CareAppointment _visit(String id, int day, {String? series}) => CareAppointment(
  id: id,
  specialty: null,
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 12, day),
  time: '10:30',
  place: 'مستشفى',
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: AppointmentStatus.scheduled,
  updatedAt: DateTime.utc(2026, 11, 15),
  seriesId: series,
);

void main() {
  group('AppointmentSeries', () {
    test('a visit on its own has no place in a booking', () {
      final CareAppointment alone = _visit('a', 5);

      expect(AppointmentSeries.of(alone, <CareAppointment>[alone]), isNull);
    });

    test('counts by date, oldest first, whatever order they arrive in', () {
      final CareAppointment third = _visit('c', 14, series: 's');
      final CareAppointment first = _visit('a', 5, series: 's');
      final CareAppointment second = _visit('b', 9, series: 's');
      final List<CareAppointment> all = <CareAppointment>[
        third,
        first,
        second,
        _visit('d', 20),
      ];

      expect(AppointmentSeries.of(first, all)?.index, 1);
      expect(AppointmentSeries.of(second, all)?.index, 2);
      expect(AppointmentSeries.of(third, all)?.index, 3);
      expect(AppointmentSeries.of(third, all)?.count, 3);
    });

    test('says nothing when the rest of the booking is not on hand', () {
      final CareAppointment lone = _visit('a', 5, series: 's');

      expect(AppointmentSeries.of(lone, <CareAppointment>[lone]), isNull);
    });
  });
}
