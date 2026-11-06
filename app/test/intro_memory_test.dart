import 'package:app/core/services/intro_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a new install has not seen the welcome', () async {
    expect(await IntroMemory.seen(), isFalse);
  });

  test('after «ابدأ» or «تخطي» the welcome is seen', () async {
    await IntroMemory.markSeen();

    expect(await IntroMemory.seen(), isTrue);
  });
}
