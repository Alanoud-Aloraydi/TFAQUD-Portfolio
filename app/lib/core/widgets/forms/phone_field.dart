import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// easy_localization also exports a TextDirection (from intl); hide it so the
// name means Flutter's TextDirection.

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

/// The mobile number in the design system's form row, as every text field
/// of the app: the small label, then the number, which a tap anywhere on
/// the row starts typing, and the fixed country code at the end. The number
/// is always written left to right, even on an Arabic page, so it reads
/// «+966 50 123 4567». The rule of the number shows under the row only when
/// what was typed breaks it.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.showError = false,
    this.error,
    this.label,
    this.autofocus = true,
  });

  final TextEditingController controller;

  /// Receives the text as typed; the cubit keeps only its digits.
  final ValueChanged<String> onChanged;

  /// Shows the rule of the number as the row's error.
  final bool showError;

  /// A refusal of the number by the server, translated; shown instead, and
  /// the row scrolls into view.
  final String? error;

  /// The row's label. Null shows "رقم الجوال", the label of the sign-in
  /// page; the page for a patient's number gives its own.
  final String? label;

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return FieldWithError.reveal(
      error: error,
      child: InsetGroup(
        children: <Widget>[
          InsetTextRow(
            label: label ?? context.tr('auth.phone_label'),
            controller: controller,
            onChanged: onChanged,
            autofocus: autofocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[PhoneNumberFormatter()],
            hint: context.tr('auth.phone_example'),
            errorText:
                error ?? (showError ? context.tr('auth.phone_hint') : null),
            ltr: true,
            trailing: Text(
              SaudiMobile.countryCode,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
