import 'dart:convert';

import 'package:app/core/services/local_keys_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Contract for storing the session tokens. Widgets and Cubits depend on
/// this interface, never on FlutterSecureStorage directly.
abstract interface class TokenStorage {
  int get revision;
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Replaces the access token only. The refresh endpoint returns a new access
  /// token and keeps the refresh token.
  Future<void> saveAccessToken(String accessToken, {int? expectedRevision});

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> clear({int? expectedRevision});
}

/// Secure storage could not read or persist the session credentials.
class TokenStorageException implements Exception {
  const TokenStorageException();
}

@LazySingleton(as: TokenStorage)
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage, this._keys);

  final FlutterSecureStorage _storage;
  final LocalKeysService _keys;
  Future<void> _writes = Future.value();
  int _revision = 0;

  @override
  int get revision => _revision;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _revision++;
    return _write(() => _persist(accessToken, refreshToken));
  }

  @override
  Future<void> saveAccessToken(String accessToken, {int? expectedRevision}) =>
      _write(() async {
        if (expectedRevision != null && expectedRevision != revision) return;
        final pair = await _readPair();
        await _persist(accessToken, pair.refresh);
      });

  @override
  Future<String?> readAccessToken() async => (await _read()).access;

  @override
  Future<String?> readRefreshToken() async => (await _read()).refresh;

  @override
  Future<void> clear({int? expectedRevision}) {
    if (expectedRevision != null && expectedRevision != revision) {
      return Future.value();
    }
    _revision++;
    return _write(() async {
      // A signed-out record prevents fallback to partially deleted legacy keys.
      await _persist(null, null);
      await Future.wait([
        _storage.delete(key: _keys.accessToken),
        _storage.delete(key: _keys.refreshToken),
      ]);
    });
  }

  Future<void> _persist(String? access, String? refresh) => _storage.write(
    key: _keys.sessionTokens,
    value: jsonEncode({'access_token': access, 'refresh_token': refresh}),
  );

  Future<({String? access, String? refresh})> _read() async {
    try {
      await _writes;
      return await _readPair();
    } on Exception {
      throw const TokenStorageException();
    }
  }

  Future<({String? access, String? refresh})> _readPair() async {
    final stored = await _storage.read(key: _keys.sessionTokens);
    if (stored != null) {
      if (jsonDecode(stored) case {
        'access_token': String? access,
        'refresh_token': String? refresh,
      }) {
        return (access: access, refresh: refresh);
      }
      throw const FormatException('Invalid stored session.');
    }
    final access = await _storage.read(key: _keys.accessToken);
    final refresh = await _storage.read(key: _keys.refreshToken);
    if (access == null || refresh == null) return (access: null, refresh: null);
    return (access: access, refresh: refresh);
  }

  Future<void> _write(Future<void> Function() action) {
    final next = _writes.then((_) async {
      try {
        await action();
      } on Exception {
        throw const TokenStorageException();
      }
    });
    // A failed operation reaches its caller without blocking later writes.
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }
}
