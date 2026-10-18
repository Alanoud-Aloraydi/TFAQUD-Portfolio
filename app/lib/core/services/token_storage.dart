import 'package:app/core/services/local_keys_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Contract for storing the session tokens. Widgets and Cubits depend on
/// this interface, never on FlutterSecureStorage directly.
abstract interface class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Replaces the access token only. The refresh endpoint returns a new access
  /// token and keeps the refresh token.
  Future<void> saveAccessToken(String accessToken);

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> clear();
}

@LazySingleton(as: TokenStorage)
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage, this._keys);

  final FlutterSecureStorage _storage;
  final LocalKeysService _keys;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keys.accessToken, value: accessToken),
      _storage.write(key: _keys.refreshToken, value: refreshToken),
    ]);
  }

  @override
  Future<void> saveAccessToken(String accessToken) =>
      _storage.write(key: _keys.accessToken, value: accessToken);

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: _keys.accessToken);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: _keys.refreshToken);

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _keys.accessToken),
      _storage.delete(key: _keys.refreshToken),
    ]);
  }
}
