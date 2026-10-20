import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

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
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? helperText;
  final TextInputAction textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.titleSmall?.copyWith(color: AppColors.ink2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          textInputAction: textInputAction,
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
