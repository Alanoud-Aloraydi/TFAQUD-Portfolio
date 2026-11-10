import 'package:app/core/utils/text_limits.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The limits count code points, as the server and PostgreSQL do.
void main() {
  group('limitCodePoints', () {
    test('keeps text within the limit as it is', () {
      expect(limitCodePoints('ريم', 30), 'ريم');
    });

    test('cuts Arabic text to the limit', () {
      expect(limitCodePoints('عبدالرحمن', 4), 'عبدا');
    });

    test('never splits an emoji into half a surrogate pair', () {
      // 😀 is one code point but two UTF-16 units: substring(0, 2) would
      // keep 'a' and half of it.
      final String cut = limitCodePoints('a😀b', 2);
      expect(cut, 'a😀');
      expect(cut.runes.length, 2);
    });
  });

  group('CodePointLengthFormatter', () {
    const CodePointLengthFormatter formatter = CodePointLengthFormatter(3);

    TextEditingValue type(String old, String next) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          ),
        );

    test('lets text within the limit through', () {
      expect(type('ab', 'abc').text, 'abc');
    });

    test('ignores typing once the field is full', () {
      expect(type('abc', 'abcd').text, 'abc');
    });

    test('counts an emoji of several code points as several', () {
      // 👨‍👩‍👧 is one visible character but five code points: the server
      // counts five, so it does not fit in three.
      expect(type('', '👨‍👩‍👧').text.runes.length, 3);
    });

    test('cuts a long paste to its start, cursor at the end', () {
      final TextEditingValue value = type('', 'abcdef');
      expect(value.text, 'abc');
      expect(value.selection, const TextSelection.collapsed(offset: 3));
    });
  });
}
