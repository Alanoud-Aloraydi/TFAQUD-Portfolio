/// Digit helpers for Arabic screens.
///
/// An Arabic keyboard can type Arabic-Indic digits or Persian digits. The app
/// keeps and shows English digits (0 to 9) everywhere, so every typed number is
/// turned into 0 to 9 first.
abstract class ArabicDigits {
  ArabicDigits._();

  // \u0660 to \u0669 are the Arabic-Indic digits; \u06F0 to \u06F9 are the
  // Persian digits.
  static const String _arabicIndic =
      '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
  static const String _persian =
      '\u06F0\u06F1\u06F2\u06F3\u06F4\u06F5\u06F6\u06F7\u06F8\u06F9';

  /// Turns Arabic-Indic and Persian digits into 0-9. Other characters stay.
  static String toWestern(String input) {
    final StringBuffer out = StringBuffer();
    for (final int rune in input.runes) {
      final String character = String.fromCharCode(rune);
      int index = _arabicIndic.indexOf(character);
      if (index < 0) index = _persian.indexOf(character);
      out.write(index >= 0 ? index.toString() : character);
    }
    return out.toString();
  }

  /// Only the digits of [input], written as 0-9.
  static String digitsOnly(String input) {
    return toWestern(input).replaceAll(RegExp(r'[^0-9]'), '');
  }
}
