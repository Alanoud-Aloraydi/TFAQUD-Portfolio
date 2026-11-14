import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text field on its own, in the design system's form row (FormGroup): a
/// white card with the small grey label on the right and the typed text
/// starting right after it. Nothing is stacked: [helperText] becomes the
/// hint inside the empty field, and an error shows under the row.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
    this.maxLength,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  /// What to type. Shown inside the field while it is empty.
  final String? helperText;
  final TextInputAction textInputAction;
  final bool autofocus;

  /// The most characters the user can type. No counter is shown.
  final int? maxLength;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      children: <Widget>[
        InsetTextRow(
          label: label,
          controller: controller,
          onChanged: onChanged,
          focusNode: focusNode,
          hint: helperText,
          errorText: errorText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          textInputAction: textInputAction,
          autofocus: autofocus,
        ),
      ],
    );
  }
}
