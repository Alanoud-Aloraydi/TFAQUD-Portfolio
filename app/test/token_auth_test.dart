import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/services/local_keys_service.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory TokenStorage used instead of the real secure storage.
class _FakeTokenStorage implements TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    access = accessToken;
  }

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

/// A request as the fake server received it.
class _Seen {
  _Seen(RequestOptions options)
    : path = options.path,
      headers = Map<String, dynamic>.of(options.headers),
      data = options.data;

  final String path;
  final Map<String, dynamic> headers;
  final Object? data;

  String? get authorization => headers['Authorization'] as String?;
}

typedef _Responder = ResponseBody Function(_Seen seen);

/// Stands in for the network: records requests and answers from a function.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this._respond);

  final _Responder _respond;
  final List<_Seen> seen = <_Seen>[];

  int count(String path) => seen.where((_Seen s) => s.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final _Seen request = _Seen(options);
    seen.add(request);
    return _respond(request);
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

ResponseBody _apiError(int status, String code) => _json(
  status,
  <String, Object>{
    'error': <String, Object>{'code': code, 'message': 'test'},
  },
);

/// Answers 401 `access_token_expired` until the request carries the new token.
_Responder _expiringServer() => (_Seen s) {
  if (s.path == '/auth/refresh') {
    return _json(200, <String, Object>{
      'access_token': 'new',
      'access_token_expires_at': '2026-01-01T00:00:00',
    });
  }
  if (s.authorization == 'Bearer new') {
    return _json(200, <String, Object>{'ok': true});
  }
  return _apiError(401, 'access_token_expired');
};

class _Client {
  _Client(this.tokens, _Responder respond) : server = _FakeServer(respond) {
    interceptor = AuthInterceptor(tokens);
    interceptor.plainDio = Dio(BaseOptions(baseUrl: _base))
      ..httpClientAdapter = server;
    dio = Dio(BaseOptions(baseUrl: _base))
      ..httpClientAdapter = server
      ..interceptors.add(interceptor);
    interceptor.sessionEnded.listen((_) => sessionEnded++);
  }

  static const String _base = 'https://test.invalid';

  final _FakeTokenStorage tokens;
  final _FakeServer server;
  late final AuthInterceptor interceptor;
  late final Dio dio;
  int sessionEnded = 0;
}

Matcher _failsWith(int status) => throwsA(
  isA<DioException>().having(
    (DioException e) => e.response?.statusCode,
    'status',
    status,
  ),
);

void main() {
  group('AuthInterceptor token header', () {
    _Responder ok() => (_Seen s) => _json(200, <String, Object>{});

    test('adds the bearer token when one is stored', () async {
      final _Client c = _Client(_FakeTokenStorage()..access = 'abc', ok());
      await c.dio.get<dynamic>('/ping');
      expect(c.server.seen.single.authorization, 'Bearer abc');
    });

    test('sends no Authorization header without a token', () async {
      final _Client c = _Client(_FakeTokenStorage(), ok());
      await c.dio.get<dynamic>('/ping');
      expect(c.server.seen.single.authorization, isNull);
    });

    test('sends no Authorization header for an empty token', () async {
      final _Client c = _Client(_FakeTokenStorage()..access = '', ok());
      await c.dio.get<dynamic>('/ping');
      expect(c.server.seen.single.authorization, isNull);
    });

    test('does not send the token to /health and /auth/refresh', () async {
      final _Client c = _Client(_FakeTokenStorage()..access = 'abc', ok());
      await c.dio.get<dynamic>('/health');
      await c.dio.post<dynamic>(
        '/auth/refresh',
        data: <String, String>{'refresh_token': 'r'},
      );
      expect(c.server.seen.map((_Seen s) => s.authorization), <String?>[
        null,
        null,
      ]);
    });
  });

  group('AuthInterceptor renewal', () {
    test('renews an expired access token and retries the request', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()
        ..access = 'old'
        ..refresh = 'r';
      final _Client c = _Client(tokens, _expiringServer());

      final Response<dynamic> response = await c.dio.get<dynamic>('/ping');

      expect(response.statusCode, 200);
      expect(tokens.access, 'new');
      expect(tokens.refresh, 'r');
      expect(c.server.seen.map((_Seen s) => s.path), <String>[
        '/ping',
        '/auth/refresh',
        '/ping',
      ]);
      expect(c.server.seen[1].authorization, isNull);
      expect(c.server.seen[1].data, <String, String>{'refresh_token': 'r'});
      expect(c.server.seen[2].authorization, 'Bearer new');
      expect(c.sessionEnded, 0);
    });

    test('concurrent expired requests share one renewal', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()
        ..access = 'old'
        ..refresh = 'r';
      final _Client c = _Client(tokens, _expiringServer());

      final List<Response<dynamic>> responses =
          await Future.wait(<Future<Response<dynamic>>>[
            c.dio.get<dynamic>('/a'),
            c.dio.get<dynamic>('/b'),
          ]);

      expect(responses.map((Response<dynamic> r) => r.statusCode), <int?>[
        200,
        200,
      ]);
      expect(c.server.count('/auth/refresh'), 1);
    });

    test('a rejected refresh token ends the session', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()
        ..access = 'old'
        ..refresh = 'r';
      final _Client c = _Client(tokens, (_Seen s) {
        if (s.path == '/auth/refresh') {
          return _apiError(401, 'invalid_refresh_token');
        }
        return _apiError(401, 'access_token_expired');
      });

      await expectLater(c.dio.get<dynamic>('/ping'), _failsWith(401));
      await Future<void>.delayed(Duration.zero);

      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
      expect(c.sessionEnded, 1);
    });

    test('a missing refresh token ends the session without a renewal', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()..access = 'old';
      final _Client c = _Client(
        tokens,
        (_Seen s) => _apiError(401, 'access_token_expired'),
      );

      await expectLater(c.dio.get<dynamic>('/ping'), _failsWith(401));
      await Future<void>.delayed(Duration.zero);

      expect(c.server.count('/auth/refresh'), 0);
      expect(tokens.access, isNull);
      expect(c.sessionEnded, 1);
    });

    test('a revoked session ends the session without a renewal', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()
        ..access = 'old'
        ..refresh = 'r';
      final _Client c = _Client(
        tokens,
        (_Seen s) => _apiError(401, 'session_revoked'),
      );

      await expectLater(c.dio.get<dynamic>('/ping'), _failsWith(401));
      await Future<void>.delayed(Duration.zero);

      expect(c.server.count('/auth/refresh'), 0);
      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
      expect(c.sessionEnded, 1);
    });

    test('a request is retried only once', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()
        ..access = 'old'
        ..refresh = 'r';
      final _Client c = _Client(tokens, (_Seen s) {
        if (s.path == '/auth/refresh') {
          return _json(200, <String, Object>{'access_token': 'new'});
        }
        return _apiError(401, 'access_token_expired');
      });

      await expectLater(c.dio.get<dynamic>('/ping'), _failsWith(401));

      expect(c.server.count('/ping'), 2);
      expect(c.server.count('/auth/refresh'), 1);
    });

    test('a renewal that cannot complete keeps the session', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()
        ..access = 'old'
        ..refresh = 'r';
      final _Client c = _Client(tokens, (_Seen s) {
        if (s.path == '/auth/refresh') {
          throw DioException.connectionError(
            requestOptions: RequestOptions(path: s.path),
            reason: 'offline',
          );
        }
        return _apiError(401, 'access_token_expired');
      });

      await expectLater(c.dio.get<dynamic>('/ping'), _failsWith(401));
      await Future<void>.delayed(Duration.zero);

      expect(tokens.access, 'old');
      expect(tokens.refresh, 'r');
      expect(c.sessionEnded, 0);
    });

    test('a 401 without a known code is passed through', () async {
      final _FakeTokenStorage tokens = _FakeTokenStorage()
        ..access = 'old'
        ..refresh = 'r';
      final _Client c = _Client(tokens, (_Seen s) => _json(401, <String, Object>{}));

      await expectLater(c.dio.get<dynamic>('/ping'), _failsWith(401));
      await Future<void>.delayed(Duration.zero);

      expect(c.server.count('/auth/refresh'), 0);
      expect(tokens.access, 'old');
      expect(c.sessionEnded, 0);
    });
  });

  group('SecureTokenStorage', () {
    late FlutterSecureStorage storage;
    late SecureTokenStorage tokens;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      storage = const FlutterSecureStorage();
      tokens = SecureTokenStorage(storage, LocalKeysService());
    });

    test('returns null before anything is saved', () async {
      expect(await tokens.readAccessToken(), isNull);
      expect(await tokens.readRefreshToken(), isNull);
    });

    test('saves and reads both tokens', () async {
      await tokens.saveTokens(accessToken: 'a', refreshToken: 'r');
      expect(await tokens.readAccessToken(), 'a');
      expect(await tokens.readRefreshToken(), 'r');
    });

    test('saveAccessToken keeps the refresh token', () async {
      await tokens.saveTokens(accessToken: 'a', refreshToken: 'r');
      await tokens.saveAccessToken('b');
      expect(await tokens.readAccessToken(), 'b');
      expect(await tokens.readRefreshToken(), 'r');
    });

    test('clear removes only the two token keys', () async {
      await storage.write(key: 'user_id', value: '7');
      await tokens.saveTokens(accessToken: 'a', refreshToken: 'r');
      await tokens.clear();
      expect(await tokens.readAccessToken(), isNull);
      expect(await tokens.readRefreshToken(), isNull);
      expect(await storage.read(key: 'user_id'), '7');
    });
  });
}
