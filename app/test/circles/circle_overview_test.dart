import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/data/models/circle_overview_model.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/circles_fakes.dart';

Map<String, dynamic> _circle(List<Map<String, dynamic>> members) =>
    <String, dynamic>{
      'circle': <String, dynamic>{
        'name': 'رعاية أمي',
        'role': 'manager',
        'can_manage_members': true,
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

CircleOverview _overview({
  bool patientIsYou = false,
  List<CircleMember> members = const <CircleMember>[
    CircleMember(name: 'Reem', isYou: true),
  ],
}) => CircleOverview(
  name: 'أمي نورة',
  patientName: 'نورة العتيبي',
  patientIsYou: patientIsYou,
  patientUsesApp: false,
  patientBirthDate: DateTime(1954, 6, 5),
  city: 'بريدة',
  canManage: true,
  members: members,
  pendingInvitations: const <CirclePendingInvitation>[],
);

void main() {
  group('CircleOverviewModel', () {
    test('reads which member is the patient', () {
      final overview = CircleOverviewModel.fromJson(
        _circle(<Map<String, dynamic>>[
          <String, dynamic>{
            'display_name': 'لينا',
            'is_you': true,
            'is_patient': false,
            'role': 'member',
            'can_edit': false,
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
      expect(overview.canManageMembers, isTrue);
      expect(overview.members.first.canEdit, isFalse);
      expect(overview.pendingInvitations.single.phoneNumber, '+966559876543');
      // Sent again: the row counts from the last time it was sent.
      expect(
        overview.pendingInvitations.single.sentAt,
        DateTime.parse('2026-11-01T10:00:00Z'),
      );
    });

    test('reads the leader and what each member may edit', () {
      final Map<String, dynamic> json = _circle(<Map<String, dynamic>>[
        <String, dynamic>{
          'display_name': 'ريم',
          'is_you': true,
          'is_leader': true,
          'role': 'manager',
          'can_edit': true,
          'edit_access': <String, dynamic>{
            'medications': true,
            'measurements': true,
            'appointments': true,
          },
        },
        <String, dynamic>{
          'display_name': 'لينا',
          'is_you': false,
          'role': 'manager',
          'can_edit': true,
          'edit_access': <String, dynamic>{
            'medications': false,
            'measurements': true,
            'appointments': false,
          },
        },
        // A server from before the areas: one answer for all three.
        <String, dynamic>{
          'display_name': 'خالد',
          'is_you': false,
          'role': 'member',
          'can_edit': false,
        },
      ]);
      (json['circle'] as Map<String, dynamic>)['can_hand_over'] = true;

      final CircleOverview overview = CircleOverviewModel.fromJson(json)
          .overview;

      expect(overview.canHandOver, isTrue);
      expect(overview.members.map((m) => m.isLeader), <bool>[
        true,
        false,
        false,
      ]);
      expect(
        overview.members[1].editAccess,
        const EditAccess(
          medications: false,
          measurements: true,
          appointments: false,
        ),
      );
      expect(overview.members[2].editAccess, const EditAccess.all(false));
      expect(overview.members[2].isViewOnly, isTrue);
    });

    test('a server without "is_patient" reads as not the patient', () {
      final overview = CircleOverviewModel.fromJson(
        _circle(<Map<String, dynamic>>[
          <String, dynamic>{'display_name': 'لينا', 'is_you': true},
        ]),
      ).overview;

      expect(overview.members.single.isPatient, isFalse);
    });

    test('reads the app mode, and none for a patient without an account', () {
      final Map<String, dynamic> json = _circle(<Map<String, dynamic>>[]);
      expect(
        CircleOverviewModel.fromJson(json).overview.appMode,
        CircleAppMode.detailed,
      );
      final Map<String, dynamic> circle =
          json['circle'] as Map<String, dynamic>;
      (circle['patient'] as Map<String, dynamic>)['app_mode'] = null;
      expect(CircleOverviewModel.fromJson(json).overview.appMode, isNull);
    });
  });

  group('CircleOverviewCubit', () {
    late CirclesFakeRepository circles;
    late CircleOverviewCubit cubit;

    setUp(() async {
      circles = CirclesFakeRepository();
      cubit = CircleOverviewCubit(CirclesUseCase(circles), 'circle-1');
      await cubit.load();
    });

    tearDown(() => cubit.close());

    group('leaveDeletesCircle', () {
      test('the only manager deletes the circle by leaving', () {
        expect(_overview().leaveDeletesCircle, isTrue);
      });

      test('the patient deletes the circle by leaving', () {
        expect(
          _overview(
            patientIsYou: true,
            members: const <CircleMember>[
              CircleMember(name: 'Reem', isYou: true),
              CircleMember(name: 'Khaled', isYou: false),
            ],
          ).leaveDeletesCircle,
          isTrue,
        );
      });

      test('a manager with another manager only leaves', () {
        expect(
          _overview(
            members: const <CircleMember>[
              CircleMember(name: 'Reem', isYou: true),
              CircleMember(name: 'Khaled', isYou: false),
              CircleMember(
                name: 'نورة',
                isYou: false,
                isPatient: true,
                isManager: false,
              ),
            ],
          ).leaveDeletesCircle,
          isFalse,
        );
      });
    });

    test('a retry after a failure shows the loading state again', () async {
      circles.circleOverview = const Error(NetworkFailure());
      await cubit.load();
      expect(cubit.state.status, CircleOverviewStatus.failure);

      circles.circleOverview = Success(CirclesFakeRepository.nouraOverview);
      final Future<void> retry = cubit.load();
      expect(cubit.state.status, CircleOverviewStatus.loading);
      await retry;
      expect(cubit.state.status, CircleOverviewStatus.ready);
    });

    test('an invitation sends the whole number and reads the circle', () async {
      final int reads = circles.circleOverviewReads;
      expect(await cubit.invite('501234567'), isNull);
      expect(circles.memberCalls.single, 'invite:+966501234567');
      expect(circles.circleOverviewReads, reads + 1);
      expect(cubit.state.acting, isFalse);
    });

    test('an invitation to your own number shows its own text', () async {
      circles.invited = const Error(SelfInvitationFailure());
      expect(
        await cubit.invite('501234567'),
        'circle_overview.self_invitation',
      );
    });

    test('a second change while one is on its way sends nothing', () async {
      final Completer<Result<void, Failure>> answer =
          Completer<Result<void, Failure>>();
      circles.pendingMemberChange = answer.future;
      final Future<String?> first = cubit.resendInvitation('i-1');
      expect(cubit.state.acting, isTrue);
      expect(await cubit.cancelInvitation('i-1'), isNull);
      expect(await cubit.leave(confirmDelete: true), isNull);
      answer.complete(const Success(null));
      expect(await first, isNull);
      expect(circles.memberCalls, <String>['resend:i-1']);
      expect(cubit.state.acting, isFalse);
    });

    test('an invitation that is gone shows why and reads the list', () async {
      circles.invitationChanged = const Error(InvitationUnavailableFailure());
      final int reads = circles.circleOverviewReads;
      expect(
        await cubit.cancelInvitation('i-1'),
        'circle_overview.invitation_unavailable',
      );
      expect(circles.circleOverviewReads, reads + 1);
    });

    test('a leave that now deletes the circle reads it again', () async {
      circles.left = const Error(LeaveDeletesCircleFailure());
      final int reads = circles.circleOverviewReads;
      expect(
        await cubit.leave(confirmDelete: false),
        'circle_overview.leave_deletes_circle',
      );
      expect(circles.memberCalls.single, 'leave:false');
      expect(circles.circleOverviewReads, reads + 1);
    });

    test('a leave that succeeds does not read the circle again', () async {
      final int reads = circles.circleOverviewReads;
      expect(await cubit.leave(confirmDelete: true), isNull);
      expect(circles.memberCalls.single, 'leave:true');
      expect(circles.circleOverviewReads, reads);
    });
  });
}
