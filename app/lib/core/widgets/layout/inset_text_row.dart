import 'package:app/core/widgets/forms/tap_to_focus.dart';
import 'package:app/core/widgets/layout/inset_row_error.dart';
import 'package:app/core/widgets/layout/inset_text_field.dart';
import 'package:app/core/widgets/layout/inset_text_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A row with the small label in its column and a borderless text field
/// after it, the card its boundary as in iOS forms; a tap anywhere on the
/// row starts typing. A short [hint] inside says what to type; an error
/// shows under the row, with an icon, so it is not color alone.
class InsetTextRow extends StatelessWidget {
  const InsetTextRow({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.trailing,
    this.autofocus = false,
    this.ltr = false,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  /// What to type, such as «مثال: 500» or «اختياري».
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// The most characters the user can type. No counter is shown.
  final int? maxLength;
  final int maxLines;
  final TextInputAction textInputAction;

  /// A small control after the field, such as a unit button.
  final Widget? trailing;
  final bool autofocus;

  /// Written left to right, from the left end, as a phone number beside its
  /// country code ([trailing]); Arabic would put its digit groups backwards.
  final bool ltr;

  @override
  Widget build(BuildContext context) => TapToFocus(
    focusNode: focusNode,
    builder: (FocusNode node) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetTextLine(
          label: label,
          multiline: maxLines > 1,
          trailing: trailing,
          field: InsetTextField(
            controller: controller,
            focusNode: node,
            autofocus: autofocus,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            hint: hint,
            ltr: ltr,
          ),
        ),
        if (errorText != null) InsetRowError(errorText!),
      ],
    ),
  );
}
