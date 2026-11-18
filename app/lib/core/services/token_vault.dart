import 'dart:convert';

import 'package:app/core/services/local_keys_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
