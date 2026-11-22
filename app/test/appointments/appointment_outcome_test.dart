import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/data/appointment_model.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/appointments/domain/appointment_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

/// A visit at 10:00 on [day] November 2026.
CareAppointment _visit(
  int day, {
  AppointmentStatus status = AppointmentStatus.scheduled,
  bool markedMissed = false,
  bool visitFilled = false,
}) => CareAppointment(
  id: 'v',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, day),
  time: '10:00',
  place: 'الحبيب',
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: status,
  updatedAt: DateTime.utc(2026, 11, 1),
  markedMissed: markedMissed,
  visitFilled: visitFilled,
);

void main() {
  // Noon on 9 November, on the patient's clock.
  final DateTime now = wallClockAt(DateTime(2026, 11, 9), '12:00');
  final DateTime today = DateTime(2026, 11, 9);

  group('how a visit went, changed from «السجل»', () {
    test('a visit whose time came: attended, cancelled or missed', () {
      for (final AppointmentStatus status in AppointmentStatus.values) {
        expect(_visit(9, status: status).outcomesAt(now), <AppointmentOutcome>[
          AppointmentOutcome.completed,
          AppointmentOutcome.cancelled,
          AppointmentOutcome.missed,
        ]);
      }
    });

    test('a cancelled visit still ahead can come back; «قادم» is read '
        'only', () {
      expect(
        _visit(12, status: AppointmentStatus.cancelled).outcomesAt(now),
        <AppointmentOutcome>[
          AppointmentOutcome.scheduled,
          AppointmentOutcome.cancelled,
        ],
      );
      expect(_visit(12).outcomesAt(now), isEmpty);
    });

    test('the ticked one is the one its badge says', () {
      expect(
        _visit(9, status: AppointmentStatus.completed).outcomeOn(now, today),
        AppointmentOutcome.completed,
      );
      expect(_visit(12).outcomeOn(now, today), AppointmentOutcome.scheduled);
      // «لم يُؤكَّد الحضور»: nothing ticked yet.
      expect(_visit(9).outcomeOn(now, today), isNull);
      expect(
        _visit(9, markedMissed: true).outcomeOn(now, today),
        AppointmentOutcome.missed,
      );
    });

    test('marked «فائت», it is missed at once, not two days later', () {
      expect(_visit(9).isMissedOn(today), isFalse);
      expect(_visit(9, markedMissed: true).isMissedOn(today), isTrue);
      expect(_visit(9, markedMissed: true).canAttendAt(now, today), isFalse);
    });

    test('«حضرت» stays while «ورقة الزيارة» has something in it', () {
      expect(
        _visit(
          9,
          status: AppointmentStatus.completed,
          visitFilled: true,
        ).outcomeLocked,
        isTrue,
      );
      expect(
        _visit(9, status: AppointmentStatus.completed).outcomeLocked,
        isFalse,
      );
    });

    test('the server says both, and a server from before says neither', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'v',
        'specialty': null,
        'kind': 'follow_up',
        'other_text': null,
        'scheduled_on': '2026-11-09',
        'time_of_day': '10:00',
        'place': 'الحبيب',
        'remote_method': null,
        'companions': <dynamic>[],
        'status': 'scheduled',
        'updated_at': '2026-11-01T00:00:00+00:00',
      };
      final CareAppointment old = AppointmentModel.tryFromJson(json)!;
      final CareAppointment marked = AppointmentModel.tryFromJson(
        <String, dynamic>{...json, 'marked_missed': true, 'visit_filled': true},
      )!;

      expect((old.markedMissed, old.visitFilled), (false, false));
      expect((marked.markedMissed, marked.visitFilled), (true, true));
    });
  });
}
