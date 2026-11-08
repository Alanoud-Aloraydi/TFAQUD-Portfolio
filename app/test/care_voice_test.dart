import 'package:app/core/l10n/care_voice.dart';
import 'package:app/features/home/data/models/home_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(CareVoice.clear);

  test('a caregiver reads the patient\'s name, the patient reads «أنت»', () {
    CareVoice.update(<String, String?>{
      'mine': null,
      'mahmoud': 'محمود',
      'blank': '  ',
    });

    expect(CareVoice.patientOf('mine'), isNull);
    expect(CareVoice.patientOf('mahmoud'), 'محمود');
    expect(CareVoice.patientOf('blank'), isNull);
    expect(CareVoice.patientOf('unknown'), isNull);
    expect(CareVoice.patientOf(null), isNull);

    CareVoice.clear();
    expect(CareVoice.patientOf('mahmoud'), isNull);
  });

  test('home tells who is the patient of each circle', () {
    final home = HomeModel.fromJson(<String, dynamic>{
      'account': <String, dynamic>{
        'id': 'yasser',
        'display_name': 'ياسر',
        'profile_complete': true,
        'avatar_code': null,
      },
      'care_circles': <dynamic>[
        <String, dynamic>{
          'id': 'c-1',
          'name': 'دائرة محمود',
          'can_manage_medications': true,
          'is_patient': false,
          'patient_name': 'محمود',
          'patient_avatar_code': null,
        },
        // An older server: the viewer is taken as the patient, as before.
        <String, dynamic>{'id': 'c-2', 'name': 'صحتي'},
      ],
    }).toEntity();

    expect(home.circles[0].isPatient, isFalse);
    expect(home.circles[0].patientName, 'محمود');
    expect(home.circles[1].isPatient, isTrue);
    expect(home.circles[1].patientName, isNull);
  });
}
