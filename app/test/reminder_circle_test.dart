import 'package:app/core/services/reminder_circle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReminderCircle circle({String? viewerId = 'a-me', bool patient = false}) =>
      ReminderCircle(
        id: 'c-1',
        name: 'أمي نورة',
        viewerId: viewerId,
        viewerIsPatient: patient,
      );

  group('remindsOfAppointment', () {
    test('the patient hears of every appointment, alone or accompanied', () {
      expect(circle(patient: true).remindsOfAppointment(<String>[]), isTrue);
      expect(
        circle(patient: true).remindsOfAppointment(<String>['a-khaled']),
        isTrue,
      );
    });

    test('a member hears of it when they go with the patient', () {
      expect(
        circle().remindsOfAppointment(<String>['a-khaled', 'a-me']),
        isTrue,
      );
    });

    test('a member who does not go hears nothing of it', () {
      expect(circle().remindsOfAppointment(<String>['a-khaled']), isFalse);
      expect(circle().remindsOfAppointment(<String>[]), isFalse);
    });

    test('a circle without a known viewer reminds of no appointment', () {
      expect(
        circle(viewerId: null).remindsOfAppointment(<String>['a-khaled']),
        isFalse,
      );
    });
  });
}
