import 'package:app/features/circles/domain/circle_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircleNames.compose', () {
    test('puts the label before the first name', () {
      expect(CircleNames.compose('أمي', 'نورة'), 'أمي نورة');
    });

    test('removes the spaces around the label and the name', () {
      expect(CircleNames.compose('  أمي ', ' نورة  '), 'أمي نورة');
    });

    test('keeps a name that is exactly at the limit', () {
      final String name = CircleNames.compose(
        'ا' * 29,
        'ب' * (CircleNames.maxLength - 30),
      );
      expect(name.length, CircleNames.maxLength);
    });

    test('cuts a name longer than the limit and leaves no space at its end',
        () {
      // 59 letters, one space and 5 letters would be 65 characters.
      final String name = CircleNames.compose('ا' * 59, 'ب' * 5);
      expect(name.length, lessThanOrEqualTo(CircleNames.maxLength));
      expect(name.endsWith(' '), isFalse);
      expect(name.startsWith('ا' * 59), isTrue);
    });
  });

  test('every label has a place in the list, "other" last', () {
    expect(CircleLabel.values.first, CircleLabel.mother);
    expect(CircleLabel.values.last, CircleLabel.other);
    expect(CircleLabel.values, hasLength(9));
  });
}
