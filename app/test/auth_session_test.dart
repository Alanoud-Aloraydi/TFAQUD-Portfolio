import 'package:app/core/services/token_storage.dart';
import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app/features/auth/data/models/account_status_response.dart';
import 'package:app/features/auth/data/repositories/auth_repository_data.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tokens extends Fake implements TokenStorage {
  @override
  int revision = 0;
  String? access = 'access';
  String? refresh = 'refresh';
  bool unavailable = false;
  bool clearFails = false;

  @override
  Future<String?> readAccessToken() async {
    if (unavailable) throw Exception('Storage unavailable');
    return access;
  }

  @override
  Future<void> clear({int? expectedRevision}) async {
    if (expectedRevision != null && revision != expectedRevision) return;
    if (clearFails) throw Exception('Storage unavailable');
    revision++;
    access = null;
    refresh = null;
  }
}

class _Remote extends Fake implements BaseAuthRemoteDataSource {
  AccountStatusResponse account = const AccountStatusResponse(
    profileComplete: true,
    appMode: 'detailed',
  );
  Exception? failure;
  Future<void> Function()? beforeCheck;
  int checks = 0;

  @override
  Future<AccountStatusResponse> checkSession() async {
    checks++;
    await beforeCheck?.call();
    final Exception? error = failure;
    if (error != null) throw error;
    return account;
  }

  @override
  Future<void> signOut() async {
    final Exception? error = failure;
    if (error != null) throw error;
  }
}

void main() {
  late _Tokens tokens;
  late _Remote remote;
  late AuthRepositoryData repository;
  late SplashCubit splash;

  setUp(() {
    tokens = _Tokens();
    remote = _Remote();
    repository = AuthRepositoryData(remote, tokens);
    splash = SplashCubit(AuthUseCase(repository));
    addTearDown(splash.close);
  });

  test('a complete account resumes without another sign-in', () async {
    await splash.decide();
    expect(splash.state, StartDestination.home);
    expect(remote.checks, 1);
  });

  test('an incomplete profile resumes onboarding after reopening', () async {
    remote.account = const AccountStatusResponse(
      profileComplete: false,
      appMode: null,
    );
    await splash.decide();
    expect(splash.state, StartDestination.onboarding);
  });

  test('without stored tokens the provider is not called', () async {
    await tokens.clear();
    await splash.decide();
    expect(splash.state, StartDestination.signIn);
    expect(remote.checks, 0);
  });

  test('an unavailable server preserves tokens and supports retry', () async {
    remote.failure = DioException.connectionError(
      requestOptions: RequestOptions(path: '/auth/session'),
      reason: 'Offline',
    );
    await splash.decide();
    expect(splash.state, StartDestination.unavailable);
    expect(tokens.access, 'access');
    remote.failure = null;
    await splash.decide();
    expect(splash.state, StartDestination.home);
  });

  test(
    'a revoked session cleared by the interceptor requires sign-in',
    () async {
      remote.beforeCheck = tokens.clear;
      remote.failure = DioException(
        requestOptions: RequestOptions(path: '/auth/session'),
      );
      await splash.decide();
      expect(splash.state, StartDestination.signIn);
    },
  );

  test('unavailable secure storage produces a retryable state', () async {
    tokens.unavailable = true;
    await splash.decide();
    expect(splash.state, StartDestination.unavailable);
  });

  test('restoration preserves simplified account mode', () async {
    remote.account = const AccountStatusResponse(
      profileComplete: true,
      appMode: 'simplified',
    );
    final result = await repository.restoreSession();
    result.when(
      (account) => expect(account?.appMode, 'simplified'),
      (_) => fail('Session restoration failed'),
    );
  });

  for (final bool confirmed in <bool>[true, false]) {
    test('logout clears tokens and reports confirmation=$confirmed', () async {
      if (!confirmed) remote.failure = Exception('Server unavailable');
      final AuthCubit cubit = AuthCubit(AuthUseCase(repository));
      addTearDown(cubit.close);
      await cubit.signOut();
      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
      expect(cubit.state, AuthSignedOutState(serverConfirmed: confirmed));
    });
  }

  test('invalid API profile state is rejected', () {
    expect(
      () => AccountStatusResponse.fromJson(<String, Object>{
        'profile_complete': true,
        'app_mode': 'unexpected',
      }),
      throwsFormatException,
    );
  });

  test('failed token removal does not claim a local logout', () async {
    tokens.clearFails = true;
    final AuthCubit cubit = AuthCubit(AuthUseCase(repository));
    addTearDown(cubit.close);
    await cubit.signOut();
    expect(tokens.access, 'access');
    expect(
      cubit.state,
      const AuthErrorState(messageKey: 'auth.sign_out_failed'),
    );
  });
}
