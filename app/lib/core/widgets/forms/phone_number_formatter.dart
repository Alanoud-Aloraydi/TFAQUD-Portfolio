import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:flutter/services.dart';

/// Keeps what the user types as a Saudi mobile number ([SaudiMobile]):
/// digits only (an Arabic keyboard may type Arabic-Indic digits), no leading
/// zero, at most nine digits, grouped like "50 123 4567" and shown in English
/// digits.
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = ArabicDigits.digitsOnly(newValue.text);
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > SaudiMobile.digits) {
      digits = digits.substring(0, SaudiMobile.digits);
    }
    final String text = SaudiMobile.group(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
