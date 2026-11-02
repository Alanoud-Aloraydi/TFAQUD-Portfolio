import 'package:app/features/circles/data/models/circle_overview_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _circle(List<Map<String, dynamic>> members) =>
    <String, dynamic>{
      'circle': <String, dynamic>{
        'name': 'رعاية أمي',
        'role': 'manager',
        'patient': <String, dynamic>{
          'first_name': 'نورة',
          'last_name': 'العتيبي',
          'is_you': false,
          'has_account': true,
          'app_mode': 'detailed',
          'birth_date': '1954-06-05',
          'city': 'بريدة',
        },
        'members': members,
        'pending_invitations': <dynamic>[
          <String, dynamic>{
            'id': 'i-1',
            'invitee_phone_number': '+966559876543',
            'created_at': '2026-10-31T09:00:00Z',
            'last_sent_at': '2026-11-01T10:00:00Z',
          },
        ],
      },
    };

void main() {
  test('reads which member is the patient', () {
    final overview = CircleOverviewModel.fromJson(
      _circle(<Map<String, dynamic>>[
        <String, dynamic>{
          'display_name': 'لينا',
          'is_you': true,
          'is_patient': false,
        },
        <String, dynamic>{
          'display_name': 'نورة',
          'is_you': false,
          'is_patient': true,
        },
      ]),
    ).overview;

    expect(overview.members.map((m) => m.isPatient), <bool>[false, true]);
    expect(overview.members.first.isYou, isTrue);
    expect(overview.pendingInvitations.single.phoneNumber, '+966559876543');
    // Sent again: the row counts from the last time it was sent.
    expect(
      overview.pendingInvitations.single.sentAt,
      DateTime.parse('2026-11-01T10:00:00Z'),
    );
  });

  test('a server without "is_patient" reads as not the patient', () {
    final overview = CircleOverviewModel.fromJson(
      _circle(<Map<String, dynamic>>[
        <String, dynamic>{'display_name': 'لينا', 'is_you': true},
      ]),
    ).overview;

    expect(overview.members.single.isPatient, isFalse);
  });
}
