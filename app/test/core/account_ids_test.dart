import 'package:app/core/utils/account_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String dashed = '6f1c2b3a-0d4e-4f5a-9b8c-7d6e5f4a3b2c';

  group('sameAccount', () {
    test('an id with and without its dashes is one account', () {
      expect(sameAccount(dashed, dashed.replaceAll('-', '')), isTrue);
      expect(sameAccount(dashed.replaceAll('-', ''), dashed), isTrue);
      expect(sameAccount(dashed.toUpperCase(), dashed), isTrue);
    });

    test('another account, or none, is not the same', () {
      expect(
        sameAccount(dashed, '00000000-0d4e-4f5a-9b8c-7d6e5f4a3b2c'),
        isFalse,
      );
      expect(sameAccount(dashed, null), isFalse);
      expect(sameAccount(null, null), isFalse);
    });
  });
}
