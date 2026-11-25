import 'package:app/app/services/token_vault.dart';
import 'package:app/core/storage/local_keys_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

export 'package:app/app/services/token_vault.dart';

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

/// Secure storage could not read or persist the session credentials.
class TokenStorageException implements Exception {
  const TokenStorageException();
}
