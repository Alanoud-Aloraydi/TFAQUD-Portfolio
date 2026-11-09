import 'package:app/core/services/simplified_voice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('arabicLanguage', () {
    test('finds the Arabic voice of iOS 17 and later', () {
      expect(arabicLanguage(<String>['en-US', 'ar-001', 'fr-FR']), 'ar-001');
    });

    test('prefers the Saudi voice when the phone has it', () {
      expect(arabicLanguage(<String>['ar-001', 'ar-SA']), 'ar-SA');
    });

    test('takes any other Arabic, whatever its case or separator', () {
      expect(arabicLanguage(<String>['en-GB', 'AR_EG']), 'AR_EG');
      expect(arabicLanguage(<String>['ar']), 'ar');
    });

    test('is null on a phone without Arabic', () {
      expect(arabicLanguage(<String>['en-US', 'arn-CL']), isNull);
      expect(arabicLanguage(<String>[]), isNull);
    });
  });
}
