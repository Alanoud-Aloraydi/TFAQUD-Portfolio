import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/services/fresh_install.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Keychain as an earlier install left it.
class _Keychain implements TokenStorage {
  _Keychain({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  int revision = 0;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> saveAccessToken(
    String accessToken, {
    int? expectedRevision,
  }) async {
    access = accessToken;
  }

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> clear({int? expectedRevision}) async {
    revision++;
    access = null;
    refresh = null;
  }
}

/// The server: records each request and answers from [respond].
class _Server implements HttpClientAdapter {
  _Server(this.respond);

  final ResponseBody Function(RequestOptions request) respond;
  final List<String> seen = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add('${options.path} ${options.headers['Authorization'] ?? ''}');
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

ResponseBody _error(int status, String code) => _json(status, <String, Object>{
  'error': <String, Object>{'code': code, 'message': 'test'},
});

Dio _dio(_Server server) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server;

void main() {
  group('FreshInstall', () {
    test('the first start of a new install is a first start, once', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await FreshInstall.check(olderBuildStarted: () async => false);
      expect(FreshInstall.firstStart, isTrue);

      await FreshInstall.check(olderBuildStarted: () async => false);
      expect(FreshInstall.firstStart, isFalse);
    });

    test('an update from a build before the mark is no first start', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await FreshInstall.check(olderBuildStarted: () async => true);

      expect(FreshInstall.firstStart, isFalse);
    });

    test('when it cannot tell, no one is signed out', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await FreshInstall.check(
        olderBuildStarted: () async => throw const _NoFiles(),
      );

      expect(FreshInstall.firstStart, isFalse);
    });
  });

  group('LeftoverSignIn', () {
    test('the app opens signed out and the old session is signed out on the '
        'server', () async {
      final _Keychain keychain = _Keychain(access: 'old', refresh: 'r');
      final _Server server = _Server((_) => ResponseBody.fromString('', 204));
      final LeftoverSignIn leftover = LeftoverSignIn(keychain, _dio(server));

      await leftover.end();
      expect(keychain.access, isNull);
      expect(keychain.refresh, isNull);
      await leftover.serverSignOut;

      expect(server.seen, <String>['/auth/sign-out Bearer old']);
    });

    test('an expired access token is renewed once to sign out', () async {
      final _Keychain keychain = _Keychain(access: 'old', refresh: 'r');
      final _Server server = _Server((RequestOptions request) {
        if (request.path == '/auth/refresh') {
          return _json(200, <String, Object>{'access_token': 'new'});
        }
        if (request.headers['Authorization'] == 'Bearer old') {
          return _error(401, 'access_token_expired');
        }
        return ResponseBody.fromString('', 204);
      });
      final LeftoverSignIn leftover = LeftoverSignIn(keychain, _dio(server));

      await leftover.end();
      await leftover.serverSignOut;

      expect(server.seen, <String>[
        '/auth/sign-out Bearer old',
        '/auth/refresh ',
        '/auth/sign-out Bearer new',
      ]);
    });

    test('a session already ended is left alone', () async {
      final _Keychain keychain = _Keychain(access: 'old', refresh: 'r');
      final _Server server = _Server((_) => _error(401, 'session_revoked'));
      final LeftoverSignIn leftover = LeftoverSignIn(keychain, _dio(server));

      await leftover.end();
      await leftover.serverSignOut;

      expect(server.seen, <String>['/auth/sign-out Bearer old']);
      expect(keychain.refresh, isNull);
    });

    test('offline, the app still opens signed out', () async {
      final _Keychain keychain = _Keychain(access: 'old', refresh: 'r');
      final _Server server = _Server(
        (RequestOptions request) => throw DioException.connectionError(
          requestOptions: request,
          reason: 'offline',
        ),
      );
      final LeftoverSignIn leftover = LeftoverSignIn(keychain, _dio(server));

      await leftover.end();
      await expectLater(leftover.serverSignOut, completes);

      expect(keychain.refresh, isNull);
    });

    test('an empty Keychain needs nothing', () async {
      final _Keychain keychain = _Keychain();
      final _Server server = _Server((_) => ResponseBody.fromString('', 204));
      final LeftoverSignIn leftover = LeftoverSignIn(keychain, _dio(server));

      await leftover.end();
      await leftover.serverSignOut;

      expect(server.seen, isEmpty);
      expect(keychain.revision, 0);
    });
  });
}

/// The app's files cannot be read.
class _NoFiles implements Exception {
  const _NoFiles();
}
