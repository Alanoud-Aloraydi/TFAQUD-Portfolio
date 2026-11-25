import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/layout/inset_field_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The borderless text field of an [InsetTextRow]: the card is its
/// boundary. Arabic digits become English ones as they are typed, and the
/// length is counted in code points.
class InsetTextField extends StatelessWidget {
  const InsetTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.autofocus,
    required this.maxLines,
    required this.textInputAction,
    this.focusNode,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.ltr = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final int maxLines;

  /// The keyboard's action on a one-line field; a longer one gets a new line.
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  /// Written left to right, from the left end, as a phone number.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
      maxLines: maxLines,
      minLines: 1,
      // Arabic is read from the right: the text starts after the label.
      textAlign: ltr ? TextAlign.left : TextAlign.start,
      textDirection: ltr ? TextDirection.ltr : null,
      style: text.bodyLarge,
      inputFormatters: <TextInputFormatter>[
        // First: an Arabic keyboard types ٠-٩; they become 0-9 before any
        // formatter that keeps only English digits.
        WesternDigitsFormatter(decimal: keyboardType?.decimal ?? false),
        ...?inputFormatters,
        // Counted in code points, as the server counts.
        if (maxLength != null) CodePointLengthFormatter(maxLength!),
      ],
      decoration: insetFieldDecoration(text, hint),
    );
  }
}
