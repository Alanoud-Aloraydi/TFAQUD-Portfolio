import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/utils/arabic_digits.dart';
// easy_localization also exports a TextDirection (from intl); hide it so the
// name means Flutter's TextDirection.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps what the user types as a Saudi mobile number: digits only (an Arabic
/// keyboard may type Arabic-Indic digits), no leading zero, at most nine
/// digits, grouped like "50 123 4567" and shown in English digits.
class PhoneNumberFormatter extends TextInputFormatter {
  static const int maxDigits = 9;

  /// "501234567" becomes "50 123 4567".
  static String display(String digits) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) out.write(' ');
      out.write(digits[i]);
    }
    return out.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = ArabicDigits.digitsOnly(newValue.text);
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final String text = display(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Label, the number field and the fixed "+966" box. The number is always
/// written left to right, even on an Arabic page.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.showError = false,
    this.label,
    this.autofocus = true,
  });

  final TextEditingController controller;

  /// Receives the text as typed; the cubit keeps only its digits.
  final ValueChanged<String> onChanged;

  /// Shows the hint in the error style (red border and an error line).
  final bool showError;

  /// The text above the field. Null shows "رقم الجوال", the label of the
  /// sign-in page; the page for a patient's number gives its own.
  final String? label;

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String hint = context.tr('auth.phone_hint');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label ?? context.tr('auth.phone_label'),
          style: text.titleSmall?.copyWith(color: AppColors.ink2),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: autofocus,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                inputFormatters: <TextInputFormatter>[PhoneNumberFormatter()],
                style: text.bodyLarge,
                decoration: InputDecoration(
                  helperText: hint,
                  helperMaxLines: 2,
                  helperStyle: text.bodySmall,
                  errorText: showError ? hint : null,
                  errorMaxLines: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const _CountryCodeBox(),
          ],
        ),
      ],
    );
  }
}

class _CountryCodeBox extends StatelessWidget {
  const _CountryCodeBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Text(
        '+966',
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
