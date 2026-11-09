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

  group('bestArabicVoice', () {
    Map<String, String> voice(String locale, String quality) =>
        <String, String>{
          'name': 'Maged',
          'locale': locale,
          'quality': quality,
          'identifier': '$locale.$quality',
        };

    test('takes a downloaded enhanced voice over the default one', () {
      expect(
        bestArabicVoice(<Map<String, String>>[
          voice('en-US', 'premium'),
          voice('ar-001', 'default'),
          voice('ar-001', 'enhanced'),
        ])?['identifier'],
        'ar-001.enhanced',
      );
    });

    test('takes a premium voice over an enhanced one', () {
      expect(
        bestArabicVoice(<Map<String, String>>[
          voice('ar-001', 'enhanced'),
          voice('ar-SA', 'premium'),
        ])?['identifier'],
        'ar-SA.premium',
      );
    });

    test('keeps the default voice when it is the only Arabic one', () {
      expect(
        bestArabicVoice(<Map<String, String>>[
          voice('ar-001', 'default'),
        ])?['identifier'],
        'ar-001.default',
      );
    });

    test('is null on a phone without an Arabic voice', () {
      expect(
        bestArabicVoice(<Map<String, String>>[voice('en-US', 'enhanced')]),
        isNull,
      );
    });
  });

  group('joinParts and partAt', () {
    final (String text, List<(int, Object?)> starts) = joinParts(<SpokenPart>[
      (id: 'greeting', text: 'صباح الخير'),
      (id: 'empty', text: '   '),
      (id: 'task', text: 'هل أخذت الدواء؟'),
    ]);

    test('reads the parts as one text, each a sentence, without the '
        'empty ones', () {
      expect(text, 'صباح الخير. هل أخذت الدواء؟');
      expect(starts, <(int, Object?)>[(0, 'greeting'), (12, 'task')]);
    });

    test('tells which part a spoken word belongs to', () {
      expect(partAt(starts, 0), 'greeting');
      expect(partAt(starts, 11), 'greeting');
      expect(partAt(starts, 12), 'task');
      expect(partAt(starts, text.length - 1), 'task');
      expect(partAt(const <(int, Object?)>[], 0), isNull);
    });
  });
}
