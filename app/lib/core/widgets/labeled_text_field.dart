import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text field with its label above it, as in the account setup design.
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
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.titleSmall?.copyWith(color: AppColors.ink2)),
        const SizedBox(height: 8),
        TextField(
          focusNode: focusNode,
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: <TextInputFormatter>[
            ...?inputFormatters,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          style: text.bodyLarge,
          decoration: InputDecoration(
            errorText: errorText,
            errorMaxLines: 2,
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: text.bodySmall,
          ),
        ),
      ],
    );
  }
}
