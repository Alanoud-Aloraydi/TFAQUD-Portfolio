import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';
import 'support/home_fakes.dart';

class _Auth implements AuthRepositoryDomain {
  int signOuts = 0;

  @override
  Future<Result<bool, Failure>> signOut() async {
    signOuts++;
    return const Success(true);
  }

  @override
  Future<Result<String, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) async => const Success('verification-id');

  @override
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) async => const Success(SignInResult(needsProfile: false));

  @override
  Future<Result<SignInResult?, Failure>> restoreSession() async =>
      const Success(null);
}

class _Onboarding implements OnboardingRepositoryDomain {
  Result<bool, Failure> result = const Success(true);
  final List<List<String>> saved = <List<String>>[];

  @override
  Future<Result<bool, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) async {
    saved.add(<String>[firstName, lastName, displayName]);
    return result;
  }
}

SentCircleRequest _sent(String id, CircleRequestStatus status) =>
    SentCircleRequest(
      id: id,
      patientPhoneNumber: '+966501234567',
      circleLabel: 'أمي',
      proposedAppMode: CircleAppMode.simplified,
      status: status,
    );

void main() {
  late CirclesFakeRepository circles;
  late _Auth auth;
  late _Onboarding onboarding;
  late HomeUseCase home;
  late AccountCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    auth = _Auth();
    onboarding = _Onboarding();
    home = HomeUseCase(HomeFakeRepository());
    cubit = AccountCubit(
      CirclesUseCase(circles),
      OnboardingUseCase(onboarding),
      AuthUseCase(auth),
      home,
    );
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('shows the account and the requests that wait for the patient',
        () async {
      circles.inbox = Success(
        CircleInbox(
          sent: <SentCircleRequest>[
            _sent('a', CircleRequestStatus.pending),
            _sent('b', CircleRequestStatus.accepted),
            _sent('c', CircleRequestStatus.declined),
          ],
          received: const [],
          invitations: const [],
        ),
      );
      await cubit.load();
      expect(cubit.state.status, AccountStatus.ready);
      expect(cubit.state.account, CirclesFakeRepository.reem);
      // A declined request is not a circle that waits for approval.
      expect(cubit.state.sent.map((SentCircleRequest r) => r.id), <String>[
        'a',
        'b',
      ]);
    });

    test('still shows the account when only the requests fail', () async {
      circles.inbox = const Error(NetworkFailure());
      await cubit.load();
      expect(cubit.state.status, AccountStatus.ready);
      expect(cubit.state.sent, isEmpty);
    });

    test('a failure to read the account can be retried', () async {
      circles.account = const Error(NetworkFailure());
      await cubit.load();
      expect(cubit.state.status, AccountStatus.failure);
      expect(cubit.state.messageKey, 'error.network');
      circles.account = const Success(CirclesFakeRepository.reem);
      await cubit.load();
      expect(cubit.state.status, AccountStatus.ready);
    });

    test('an ended sign-in is reported', () async {
      circles.account = const Error(SessionExpiredFailure());
      await cubit.load();
      expect(cubit.state.sessionEnded, isTrue);
    });
  });

  group('changing the names', () {
    setUp(() => cubit.load());

    test('sends all three names, trimmed, and shows them at once', () async {
      final Future<String?> signal = home.changes.first;
      final String? failure = await cubit.saveProfile(
        firstName: ' Reem ',
        lastName: ' Alahmadi',
        displayName: ' Ree ',
      );
      expect(failure, isNull);
      expect(onboarding.saved.single, <String>['Reem', 'Alahmadi', 'Ree']);
      expect(cubit.state.account?.displayName, 'Ree');
      // The phone number and the circle of the account are kept.
      expect(cubit.state.account?.phoneNumber, '+966501234567');
      expect(cubit.state.noticeKey, 'account.saved');
      // The home screen loads again, for the letter on its top bar.
      expect(await signal, isNull);
    });

    test('an empty name sends nothing', () async {
      expect(
        await cubit.saveProfile(
          firstName: 'Reem',
          lastName: '  ',
          displayName: 'Reem',
        ),
        'circles.field_required',
      );
      expect(onboarding.saved, isEmpty);
    });

    test('a refusal gives the message back and keeps the old names', () async {
      onboarding.result = const Error(NetworkFailure());
      expect(
        await cubit.saveProfile(
          firstName: 'Reem',
          lastName: 'Alahmadi',
          displayName: 'Ree',
        ),
        'error.network',
      );
      expect(cubit.state.account?.displayName, 'Reem');
      expect(cubit.state.noticeKey, isNull);
    });

    test('the notice can be cleared once it was shown', () async {
      await cubit.saveProfile(
        firstName: 'Reem',
        lastName: 'Alahmadi',
        displayName: 'Ree',
      );
      cubit.messagesShown();
      expect(cubit.state.noticeKey, isNull);
    });
  });

  group('canceling a request', () {
    test('takes it off the list', () async {
      circles.inbox = Success(
        CircleInbox(
          sent: <SentCircleRequest>[
            _sent('a', CircleRequestStatus.pending),
            _sent('b', CircleRequestStatus.pending),
          ],
          received: const [],
          invitations: const [],
        ),
      );
      await cubit.load();
      expect(await cubit.cancelRequest('a'), isTrue);
      expect(circles.canceledIds, <String>['a']);
      expect(cubit.state.sent.map((SentCircleRequest r) => r.id), <String>['b']);
      expect(cubit.state.noticeKey, 'account.request_canceled');
    });

    test('a refusal keeps the list and says why', () async {
      circles.inbox = Success(
        CircleInbox(
          sent: <SentCircleRequest>[_sent('a', CircleRequestStatus.pending)],
          received: const [],
          invitations: const [],
        ),
      );
      await cubit.load();
      circles.canceled = const Error(NetworkFailure());
      expect(await cubit.cancelRequest('a'), isFalse);
      expect(cubit.state.sent, hasLength(1));
      expect(cubit.state.errorKey, 'error.network');
    });
  });

  group('deleting the account', () {
    setUp(() => cubit.load());

    test('asks first, and nothing is deleted when the person says no', () {
      cubit.startDelete();
      expect(cubit.state.deletePrompt, DeletePrompt.confirm);
      cubit.cancelDelete();
      expect(cubit.state.deletePrompt, DeletePrompt.none);
      expect(circles.deletions, isEmpty);
    });

    test('an account with no circles is deleted and signed out', () async {
      cubit.startDelete();
      await cubit.confirmDelete();
      expect(circles.deletions.single, const AccountDeletion());
      expect(auth.signOuts, 1);
      expect(cubit.state.signedOut, isTrue);
      expect(cubit.state.deleting, isFalse);
    });

    test('the patient of a circle is asked what happens to it', () async {
      circles.deleted = const Error(PatientChoiceRequiredFailure());
      cubit.startDelete();
      await cubit.confirmDelete();
      expect(cubit.state.deletePrompt, DeletePrompt.patientChoice);
      expect(cubit.state.signedOut, isFalse);
      expect(auth.signOuts, 0);

      circles.deleted = const Success(null);
      await cubit.choosePatient(PatientChoice.keep);
      expect(
        circles.deletions.last,
        const AccountDeletion(patientChoice: PatientChoice.keep),
      );
      expect(cubit.state.signedOut, isTrue);
    });

    test('the only manager of a circle is asked about those circles',
        () async {
      circles.deleted = const Error(LastManagerFailure());
      cubit.startDelete();
      await cubit.confirmDelete();
      expect(cubit.state.deletePrompt, DeletePrompt.lastManager);

      circles.deleted = const Success(null);
      await cubit.confirmLastManager();
      expect(
        circles.deletions.last,
        const AccountDeletion(deleteLastManagedCircles: true),
      );
      expect(cubit.state.signedOut, isTrue);
    });

    test('the choices are kept across the questions', () async {
      circles.deleted = const Error(PatientChoiceRequiredFailure());
      cubit.startDelete();
      await cubit.confirmDelete();
      circles.deleted = const Error(LastManagerFailure());
      await cubit.choosePatient(PatientChoice.delete);
      expect(cubit.state.deletePrompt, DeletePrompt.lastManager);
      circles.deleted = const Success(null);
      await cubit.confirmLastManager();
      expect(
        circles.deletions.last,
        const AccountDeletion(
          patientChoice: PatientChoice.delete,
          deleteLastManagedCircles: true,
        ),
      );
    });

    test('another failure shows its text and deletes nothing', () async {
      circles.deleted = const Error(NetworkFailure());
      cubit.startDelete();
      await cubit.confirmDelete();
      expect(cubit.state.errorKey, 'error.network');
      expect(cubit.state.deletePrompt, DeletePrompt.none);
      expect(cubit.state.signedOut, isFalse);
      expect(auth.signOuts, 0);
    });
  });
}
