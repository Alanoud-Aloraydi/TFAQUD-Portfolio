import 'package:flutter/services.dart';

/// [value] cut to at most [max] Unicode code points.
///
/// The server and PostgreSQL count length in code points, while Dart's
/// `String.length` counts UTF-16 units and Flutter's field limit counts
/// visible characters. Cutting by code points never splits a surrogate
/// pair, so the result is always valid text the server accepts.
String limitCodePoints(String value, int max) {
  final Runes runes = value.runes;
  if (runes.length <= max) return value;
  return String.fromCharCodes(runes.take(max));
}

/// Stops a text field at [maxLength] Unicode code points, the unit the API
/// validates, so a field never holds text the server refuses for its
/// length (an emoji made of several code points counts as several).
class CodePointLengthFormatter extends TextInputFormatter {
  const CodePointLengthFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= maxLength) return newValue;
    // Already full: the extra typing is ignored, as with the built-in limit.
    if (oldValue.text.runes.length >= maxLength) return oldValue;
    // A paste that goes past the limit keeps its start.
    final String cut = limitCodePoints(newValue.text, maxLength);
    return TextEditingValue(
      text: cut,
      selection: TextSelection.collapsed(offset: cut.length),
    );
  }
}
