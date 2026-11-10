import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A random id for this install of the app, kept in the secure storage.
///
/// The app sends it as `X-Device-Id` when it asks for a sign-in code: the
/// server counts the codes one phone asks for, so one phone cannot send
/// codes to many numbers. It names nobody and changes after a reinstall.
class DeviceId {
  DeviceId(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'device_id';

  String? _id;

  /// The id, made the first time. Without the storage it lives until the
  /// app closes.
  Future<String> read() async {
    final String? known = _id;
    if (known != null) return known;
    try {
      final String? stored = await _storage.read(key: _key);
      if (stored != null && stored.isNotEmpty) return _id = stored;
    } on Exception {
      return _id = _make();
    }
    final String made = _make();
    try {
      await _storage.write(key: _key, value: made);
    } on Exception {
      // Kept in memory only.
    }
    return _id = made;
  }

  /// 32 random hex digits.
  static String _make() {
    final Random random = Random.secure();
    return List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
