import 'package:app/core/utils/arabic_digits.dart';
import 'package:flutter/services.dart';

/// Keeps only digits (Western or Arabic-Indic) and cuts the text at [length].
class OtpDigitsFormatter extends TextInputFormatter {
  OtpDigitsFormatter(this.length);

  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = ArabicDigits.digitsOnly(newValue.text);
    if (digits.length > length) digits = digits.substring(0, length);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
