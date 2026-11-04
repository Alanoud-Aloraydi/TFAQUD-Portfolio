import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Loads and updates photos scoped to the active account session.
class PrivatePhotoRepository extends ChangeNotifier {
  PrivatePhotoRepository(this._client, this._tokens)
    : _sessionRevision = _tokens.revision;

  final DioClient _client;
  final TokenStorage _tokens;
  int _sessionRevision;
  final Map<String, Future<Uint8List?>> _photos = {};

  Future<Uint8List?> load(String path) {
    if (_sessionRevision != _tokens.revision) {
      _photos.clear();
      _sessionRevision = _tokens.revision;
    }
    return _photos.putIfAbsent(path, () => _fetch(path));
  }

  Future<Uint8List?> _fetch(String path) async {
    try {
      final response = await _client.dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      _photos.remove(path);
      rethrow;
    }
  }

  Future<void> save(String path, Uint8List bytes) async {
    await _client.dio.put<void>(
      path,
      data: bytes,
      options: Options(contentType: 'image/png'),
    );
    _photos.remove(path);
    notifyListeners();
  }

  Future<void> remove(String path) async {
    await _client.delete(path);
    _photos.remove(path);
    notifyListeners();
  }

  Future<void> chooseAvatar(String path, String code) async {
    await _client.put(path, data: {'avatar_code': code});
    _photos.clear();
    notifyListeners();
  }

  void clear() {
    _photos.clear();
    notifyListeners();
  }
}
