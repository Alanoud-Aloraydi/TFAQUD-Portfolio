import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The look of a text field inside a form row: no border and no fill (the
/// card is its boundary), and a light [hint] while it is empty.
InputDecoration insetFieldDecoration(TextTheme text, String? hint) =>
    InputDecoration(
      hintText: hint,
      hintStyle: text.bodyMedium?.copyWith(
        color: AppSemanticColors.borderControlBase,
      ),
      filled: false,
      isDense: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    );
