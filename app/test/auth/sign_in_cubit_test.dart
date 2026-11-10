import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/failures/invalid_code_failure.dart';
import 'package:app/features/auth/domain/failures/sign_in_failures.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

class _Auth implements AuthRepositoryDomain {
  final List<({String phone, String? id})> requests =
      <({String phone, String? id})>[];
  int verifies = 0;

  /// When set, a code request waits for it.
  Completer<void>? gate;

  Result<CodeRequest, Failure> codeResult = const Success(
    CodeRequest(verificationId: 'v1', resendAfterSeconds: 30),
  );
  Result<SignInResult, Failure> verifyResult = const Success(
    SignInResult(needsProfile: false),
  );

  @override
  Future<Result<CodeRequest, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) async {
    requests.add((phone: phone, id: verificationId));
    await gate?.future;
    return codeResult;
  }

  @override
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    verifies++;
    return verifyResult;
  }

  @override
  Future<Result<bool, Failure>> signOut() async => const Success(true);

  @override
  Future<Result<SignInResult?, Failure>> restoreSession() async =>
      const Success(null);
}

void main() {
  late _Auth auth;
  late DateTime now;
  late SignInCubit cubit;

  setUp(() {
    auth = _Auth();
    now = DateTime.utc(2026, 1, 1, 12);
    cubit = SignInCubit(AuthUseCase(auth), clock: () => now);
  });

  // A countdown test (`testWidgets`) closes the cubit itself, inside its
  // fake time, so no timer is left pending when it ends. Closing it again
  // here would await a future of that finished fake-time zone, whose
  // microtasks never run again: the test would hang until its timeout.
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  Future<void> sent() async {
    cubit.phoneChanged('501234567');
    await cubit.sendCode();
  }

  group('sending the code', () {
    test('a number that is not valid sends nothing', () async {
      cubit.phoneChanged('12');
      expect(await cubit.sendCode(), isFalse);
      expect(cubit.state.showPhoneError, isTrue);
      expect(auth.requests, isEmpty);
    });

    test('sends the whole number and keeps the request id', () async {
      cubit.phoneChanged('501234567');
      expect(await cubit.sendCode(), isTrue);
      expect(auth.requests.single, (phone: '+966501234567', id: null));
      expect(cubit.state.status, SignInStatus.codeSent);
      expect(cubit.state.verificationId, 'v1');
      expect(cubit.state.resendSeconds, 30);
    });

    test('a second tap while sending sends nothing more', () async {
      auth.gate = Completer<void>();
      cubit.phoneChanged('501234567');
      final Future<bool> first = cubit.sendCode();
      expect(await cubit.sendCode(), isFalse);
      auth.gate!.complete();
      expect(await first, isTrue);
      expect(auth.requests, hasLength(1));
    });

    test('a refusal shows its message and starts no countdown', () async {
      auth.codeResult = const Error(TooManyCodesFailure());
      await sent();
      expect(cubit.state.status, SignInStatus.idle);
      expect(cubit.state.errorKey, 'auth.too_many_codes');
      expect(cubit.state.resendSeconds, 0);
    });

    testWidgets('resend_wait starts the countdown it names', (
      WidgetTester tester,
    ) async {
      auth.codeResult = const Error(ResendWaitFailure(75));
      await sent();
      expect(cubit.state.errorKey, 'auth.resend_wait');
      expect(cubit.state.resendSeconds, 75);
      await cubit.close();
    });

    test('the answer for a number the user left is dropped', () async {
      auth.gate = Completer<void>();
      cubit.phoneChanged('501234567');
      final Future<bool> pending = cubit.sendCode();
      cubit.backToPhone();
      auth.gate!.complete();
      expect(await pending, isFalse);
      expect(cubit.state.status, SignInStatus.idle);
      expect(cubit.state.verificationId, isNull);
    });
  });

  group('the resend countdown', () {
    testWidgets('counts down from the clock, one second at a time', (
      WidgetTester tester,
    ) async {
      await sent();
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.resendSeconds, 29);
      await cubit.close();
    });

    testWidgets('shows the true wait after the phone slept', (
      WidgetTester tester,
    ) async {
      await sent();
      // The timer did not run for 20 s; the clock did.
      now = now.add(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.resendSeconds, 10);
      await cubit.close();
    });

    testWidgets('a phone clock moved back does not lengthen the wait', (
      WidgetTester tester,
    ) async {
      await sent();
      now = now.subtract(const Duration(hours: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.resendSeconds, 30);
      await cubit.close();
    });

    testWidgets('ends at zero, then a resend stays in the same request', (
      WidgetTester tester,
    ) async {
      await sent();
      expect(await cubit.resendCode(), isFalse);
      now = now.add(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.resendSeconds, 0);
      expect(await cubit.resendCode(), isTrue);
      expect(auth.requests.last.id, 'v1');
      await cubit.close();
    });

    testWidgets('closing the cubit stops the timer', (
      WidgetTester tester,
    ) async {
      await sent();
      await cubit.close();
      // A timer left running makes the test fail when it ends.
    });
  });

  group('checking the code', () {
    test('a short code is refused without asking the server', () async {
      await sent();
      cubit.codeChanged('123');
      expect(await cubit.verify(), isFalse);
      expect(cubit.state.errorKey, 'auth.code_incomplete');
      expect(auth.verifies, 0);
    });

    test('a wrong code clears the boxes and keeps the request', () async {
      await sent();
      auth.verifyResult = const Error(InvalidCodeFailure());
      cubit.codeChanged('123456');
      expect(await cubit.verify(), isFalse);
      expect(cubit.state.code, isEmpty);
      expect(cubit.state.errorKey, 'auth.code_wrong');
      expect(cubit.state.verificationId, 'v1');
      expect(cubit.state.status, SignInStatus.codeSent);
    });

    test('the third wrong code closes the request', () async {
      await sent();
      auth.verifyResult = const Error(TooManyAttemptsFailure());
      cubit.codeChanged('123456');
      await cubit.verify();
      expect(cubit.state.verificationId, isNull);
      // Without a request the next check asks for a new code.
      cubit.codeChanged('123456');
      await cubit.verify();
      expect(cubit.state.errorKey, 'auth.start_again');
      expect(auth.verifies, 1);
    });

    test('a correct code reports where to go, once', () async {
      await sent();
      auth.verifyResult = const Success(
        SignInResult(needsProfile: true, appMode: CircleAppMode.simplified),
      );
      cubit.codeChanged('123456');
      expect(await cubit.verify(), isTrue);
      expect(cubit.state.status, SignInStatus.verified);
      expect(cubit.state.needsProfile, isTrue);
      expect(cubit.state.appMode, CircleAppMode.simplified);
      // A late second tap does not check the used code again.
      expect(await cubit.verify(), isFalse);
      expect(auth.verifies, 1);
    });

    test('going back forgets the request and the code', () async {
      await sent();
      cubit.codeChanged('123456');
      cubit.backToPhone();
      expect(cubit.state.verificationId, isNull);
      expect(cubit.state.code, isEmpty);
      expect(cubit.state.resendSeconds, 0);
      // The number stays for the phone page.
      expect(cubit.state.phone, '501234567');
    });
  });
}
