import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/layout/inset_row_label.dart';
import 'package:flutter/material.dart';

/// What an [InsetRow] shows before its trailing parts, by kind of row.
extension InsetRowContent on InsetRow {
  /// The label alone; or the icon and the label of an action row; or the
  /// small label, then the value or its placeholder, of a field row.
  List<Widget> content(TextTheme text) {
    final String? shown = value ?? placeholder;
    return labelOnly
        ? <Widget>[Expanded(child: Text(label, style: text.bodyLarge))]
        : leading != null
        ? <Widget>[
            IconTheme.merge(
              data: IconThemeData(
                color: labelColor ?? AppSemanticColors.textPrimary,
                size: AppSizes.iconSmall,
              ),
              child: leading!,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: text.bodyLarge?.copyWith(color: labelColor),
              ),
            ),
          ]
        : <Widget>[
            InsetRowLabel(label),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: shown == null
                  ? const SizedBox.shrink()
                  : Text(
                      shown,
                      style: value == null
                          ? text.bodyMedium?.copyWith(
                              color: AppSemanticColors.borderControlBase,
                            )
                          : text.bodyLarge,
                    ),
            ),
          ];
  }
}
