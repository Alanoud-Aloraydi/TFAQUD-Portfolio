import 'package:app/core/l10n/arabic_counts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Arabic counts take the form Arabic uses for each number', () {
    final Map<int, String> forms = <int, String>{
      0: 'zero',
      1: 'one',
      2: 'two',
      3: 'few',
      10: 'few',
      11: 'many',
      90: 'many',
      99: 'many',
      100: 'other',
      101: 'other',
      102: 'other',
      103: 'few',
      111: 'many',
    };
    forms.forEach((int count, String form) {
      expect(arabicPluralForm(count), form, reason: '$count');
    });
  });
}
