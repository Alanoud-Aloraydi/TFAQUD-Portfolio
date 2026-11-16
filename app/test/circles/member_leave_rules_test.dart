import 'package:app/features/circles/data/models/circle_overview_model.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _circle(String role) => <String, dynamic>{
  'circle': <String, dynamic>{
    'name': 'رعاية أمي',
    'role': role,
    'patient': <String, dynamic>{
      'first_name': 'نورة',
      'last_name': 'العتيبي',
      'is_you': false,
      'has_account': true,
      'app_mode': 'detailed',
      'birth_date': '1954-06-05',
      'city': 'بريدة',
    },
    'members': <dynamic>[],
  },
};

CircleOverview _overview(List<CircleMember> members) => CircleOverview(
  name: 'أمي نورة',
  patientName: 'نورة العتيبي',
  patientIsYou: false,
  patientUsesApp: true,
  patientBirthDate: DateTime(1954, 6, 5),
  city: 'بريدة',
  canManage: true,
  members: members,
  pendingInvitations: const <CirclePendingInvitation>[],
);

void main() {
  group('who may leave', () {
    test('a manager and a paused member may, a simplified patient may not', () {
      bool canLeave(String role) =>
          CircleOverviewModel.fromJson(_circle(role)).overview.canLeave;

      expect(canLeave('manager'), isTrue);
      expect(canLeave('member'), isTrue);
      expect(canLeave('simplified_patient'), isFalse);
    });

    test('a paused member cannot manage the circle', () {
      final CircleOverview overview = CircleOverviewModel.fromJson(
        _circle('member'),
      ).overview;

      expect(overview.canManage, isFalse);
    });
  });

  group('leaveDeletesCircle with a paused member', () {
    test('the only manager with a paused member still just leaves', () {
      final CircleOverview overview = _overview(const <CircleMember>[
        CircleMember(name: 'Reem', isYou: true),
        CircleMember(name: 'Lina', isYou: false, isManager: false),
      ]);

      expect(overview.leaveDeletesCircle, isFalse);
    });

    test('a paused member only leaves', () {
      final CircleOverview overview = _overview(const <CircleMember>[
        CircleMember(name: 'Lina', isYou: true, isManager: false),
        CircleMember(name: 'نورة', isYou: false, isPatient: true),
      ]);

      expect(overview.leaveDeletesCircle, isFalse);
    });
  });

  group('CircleMember', () {
    test('a member with paused editing is view only', () {
      const CircleMember paused = CircleMember(
        name: 'Lina',
        isYou: false,
        isManager: false,
      );

      expect(paused.isViewOnly, isTrue);
      expect(paused.canEdit, isFalse);
    });

    test('a manager and the listed patient are not view only', () {
      const CircleMember manager = CircleMember(name: 'Reem', isYou: false);
      const CircleMember patient = CircleMember(
        name: 'نورة',
        isYou: false,
        isPatient: true,
        isManager: false,
      );

      expect(manager.isViewOnly, isFalse);
      expect(patient.isViewOnly, isFalse);
    });
  });
}
