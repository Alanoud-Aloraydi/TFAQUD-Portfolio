import 'package:app/core/services/appointment_audience.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool goes({
    bool isPatient = false,
    String? viewerId = 'a-me',
    List<String> picked = const <String>[],
  }) => goesToAppointment(
    isPatient: isPatient,
    viewerId: viewerId,
    companionIds: picked,
  );

  group('goesToAppointment', () {
    test('the patient is at their own visit, accompanied or not', () {
      expect(goes(isPatient: true), isTrue);
      expect(goes(isPatient: true, picked: <String>['a-khaled']), isTrue);
    });

    test('a companion of this visit is asked', () {
      expect(goes(picked: <String>['a-khaled', 'a-me']), isTrue);
    });

    test('accompanying is per visit, so another visit\'s companion is not '
        'asked about this one', () {
      // There is no standing «مرافق» of the circle: each appointment
      // carries its own list, and «حضرت» follows that list alone.
      expect(goes(picked: <String>['a-khaled']), isFalse);
      expect(goes(), isFalse);
    });

    test('an unknown viewer is asked nothing', () {
      expect(goes(viewerId: null, picked: <String>['a-khaled']), isFalse);
    });

    test('an unknown viewer who is the patient is still asked', () {
      expect(goes(viewerId: null, isPatient: true), isTrue);
    });
  });
}
