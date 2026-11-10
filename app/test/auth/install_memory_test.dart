import 'package:app/features/auth/data/datasources/device_id.dart';
import 'package:app/features/auth/data/datasources/intro_memory.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeviceId', () {
    late FlutterSecureStorage storage;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      storage = const FlutterSecureStorage();
    });

    test('is 32 hex digits, the form the server accepts', () async {
      final String id = await DeviceId(storage).read();
      expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('stays the same for this install', () async {
      final String first = await DeviceId(storage).read();
      // A new object over the same storage is the same install.
      expect(await DeviceId(storage).read(), first);
    });

    test('differs between installs', () async {
      final String first = await DeviceId(storage).read();
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      expect(await DeviceId(const FlutterSecureStorage()).read(), isNot(first));
    });
  });

  group('IntroMemory', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('a new install has not seen the welcome', () async {
      expect(await IntroMemory.seen(), isFalse);
    });

    test('after «ابدأ» or «تخطي» the welcome is seen', () async {
      await IntroMemory.markSeen();

      expect(await IntroMemory.seen(), isTrue);
    });
  });
}
