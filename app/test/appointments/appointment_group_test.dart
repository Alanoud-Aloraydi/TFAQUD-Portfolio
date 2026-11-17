import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_group.dart';
import 'package:app/features/appointments/presentation/appointment_record_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// 10 December 2026, the morning the lists are read.
final DateTime _now = DateTime.utc(2026, 12, 10, 9);

CareAppointment _visit(
  String id,
  int day, {
  String? series,
  AppointmentStatus status = AppointmentStatus.scheduled,
}) => CareAppointment(
  id: id,
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 12, day),
  time: '10:30',
  place: 'مستشفى',
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: status,
  updatedAt: DateTime.utc(2026, 11, 15),
  seriesId: series,
);

List<String> _ids(List<CareAppointment> visits) => <String>[
  for (final CareAppointment visit in visits) visit.id,
];

void main() {
  // A booking of four dates: two behind, two ahead.
  final CareAppointment first = _visit(
    'b1',
    2,
    series: 's',
    status: AppointmentStatus.completed,
  );
  final CareAppointment second = _visit('b2', 6, series: 's');
  final CareAppointment third = _visit('b3', 14, series: 's');
  final CareAppointment fourth = _visit('b4', 21, series: 's');
  final CareAppointment alone = _visit('a', 18);
  final List<CareAppointment> all = <CareAppointment>[
    fourth,
    alone,
    second,
    first,
    third,
  ];

  group('AppointmentGroup', () {
    test('one card for a booking: its next date, the rest by date', () {
      final List<AppointmentGroup> groups = AppointmentGroup.of(
        upcomingAppointments(all, _now),
        all,
        _now,
      );

      expect(<String>[for (final g in groups) g.shown.id], <String>['b3', 'a']);
      // The dates behind are listed too, read from every visit known.
      expect(_ids(groups.first.others), <String>['b1', 'b2', 'b4']);
      expect(groups.last.others, isEmpty);
    });

    test('a booking with nothing ahead shows its last date', () {
      final List<CareAppointment> past = <CareAppointment>[first, second];
      final List<AppointmentGroup> groups = AppointmentGroup.of(
        past,
        past,
        _now,
      );

      expect(groups.single.shown.id, 'b2');
      expect(_ids(groups.single.others), <String>['b1']);
    });

    test('keeps the order of the list it is given', () {
      final List<AppointmentGroup> groups = AppointmentGroup.of(
        AppointmentRecordFilter.all.pick(all, _now),
        all,
        _now,
      );

      // Newest first, as «السجل» lists them: the lone visit of the 18th,
      // then the booking's card, standing where its 14th is.
      expect(<String>[for (final g in groups) g.shown.id], <String>['a', 'b3']);
    });

    test('a filter narrows the cards, not the other dates', () {
      final List<AppointmentGroup> groups = AppointmentGroup.of(
        AppointmentRecordFilter.previous.pick(all, _now),
        all,
        _now,
      );

      expect(groups.single.shown.id, 'b2');
      expect(_ids(groups.single.others), <String>['b1', 'b3', 'b4']);
    });

    test('«الخطة» counts a booking once', () {
      expect(upcomingBookings(all, _now), 2);
    });
  });
}
