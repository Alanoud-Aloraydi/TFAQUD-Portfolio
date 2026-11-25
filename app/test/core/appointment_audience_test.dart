import 'package:app/core/utils/appointment_audience.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool goes({
    bool isPatient = false,
    String? viewerId = 'a-me',
    List<String> picked = const <String>[],
    bool standsIn = false,
  }) => goesToAppointment(
    isPatient: isPatient,
    viewerId: viewerId,
    companionIds: picked,
    standsIn: standsIn,
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

    test('the signed-in id without dashes is the companion id with them', () {
      // «الرئيسية» names the account without its UUID's dashes, a visit's
      // companions with them: Leen going with Khaled is still asked.
      const String dashed = '6f1c2b3a-0d4e-4f5a-9b8c-7d6e5f4a3b2c';
      expect(
        goes(viewerId: dashed.replaceAll('-', ''), picked: <String>[dashed]),
        isTrue,
      );
      expect(
        goes(viewerId: dashed.toUpperCase(), picked: <String>[dashed]),
        isTrue,
      );
    });

    test('the leader of a patient without a phone goes when nobody else '
        'does', () {
      // «بدون مرافق» and no phone: the leader is reminded and answers.
      expect(goes(standsIn: true), isTrue);
      // With companions, they are the ones who go.
      expect(goes(standsIn: true, picked: <String>['a-khaled']), isFalse);
      expect(
        goes(standsIn: true, picked: <String>['a-khaled', 'a-me']),
        isTrue,
      );
    });

    test('an unknown viewer is asked nothing', () {
      expect(goes(viewerId: null, picked: <String>['a-khaled']), isFalse);
    });

    test('an unknown viewer who is the patient is still asked', () {
      expect(goes(viewerId: null, isPatient: true), isTrue);
    });
  });
}
