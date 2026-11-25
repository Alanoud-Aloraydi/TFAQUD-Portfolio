import 'dart:convert';

import 'package:app/core/storage/local_keys_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

/// Persists authentication tokens in secure storage.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(FlutterSecureStorage storage, LocalKeysService keys)
    : _vault = TokenVault(storage, keys);

  final TokenVault _vault;
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
    return _write(() => _vault.persist(accessToken, refreshToken));
  }

  @override
  Future<void> saveAccessToken(String accessToken, {int? expectedRevision}) =>
      _write(() async {
        if (expectedRevision != null && expectedRevision != revision) return;
        final pair = await _vault.readPair();
        await _vault.persist(accessToken, pair.refresh);
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
      await _vault.persist(null, null);
      await _vault.deleteLegacy();
    });
  }

  Future<({String? access, String? refresh})> _read() async {
    try {
      await _writes;
      return await _vault.readPair();
    } on Exception {
      throw const TokenStorageException();
    }
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

/// The session tokens as they sit in secure storage: one record, and the
/// two keys older installs used.
class TokenVault {
  const TokenVault(this._storage, this._keys);

  final FlutterSecureStorage _storage;
  final LocalKeysService _keys;

  Future<void> persist(String? access, String? refresh) => _storage.write(
    key: _keys.sessionTokens,
    value: jsonEncode({'access_token': access, 'refresh_token': refresh}),
  );

  /// Deletes the two keys older installs used.
  Future<void> deleteLegacy() => Future.wait([
    _storage.delete(key: _keys.accessToken),
    _storage.delete(key: _keys.refreshToken),
  ]);

  Future<({String? access, String? refresh})> readPair() async {
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
}

/// Secure storage could not read or persist the session credentials.
class TokenStorageException implements Exception {
  const TokenStorageException();
}
