import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:flutter/material.dart';

/// One tappable row. With a [leading] icon it is an action row, such as
/// «إضافة موعد جرعة»: the icon and the label in ink. Otherwise it is a field
/// row: the small label in its column, then the value (or a placeholder)
/// starting right after it, and an optional chevron at the end. At least 48
/// high, so it is easy to tap.
class InsetRow extends StatelessWidget {
  const InsetRow({
    super.key,
    required this.label,
    this.value,
    this.placeholder,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.focusNode,
    this.labelColor,
    this.errorText,
    this.labelOnly = false,
  });

  final String label;

  /// The chosen value, in ink.
  final String? value;

  /// Shown when there is no value, in a lighter grey.
  final String? placeholder;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final FocusNode? focusNode;

  /// For an action row such as «إضافة موعد».
  final Color? labelColor;

  /// Shown under the row, lined up with the value.
  final String? errorText;

  /// A row that is only its label, in ink, such as one choice in a list.
  final bool labelOnly;

  @override
  Widget build(BuildContext context) {
    // One VoiceOver stop per row: the label, the value and the tap.
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          focusNode: focusNode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InsetRowLine(
                content: content(Theme.of(context).textTheme),
                trailing: trailing,
                showChevron: showChevron,
              ),
              if (errorText != null) InsetRowError(errorText!),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small grey label at the start of a form row. It reads like a hint, so
/// the value or the typed text, set larger in ink, is what stands out. Every
/// label has the same column width, so values line up from row to row.
class InsetRowLabel extends StatelessWidget {
  const InsetRowLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.formLabel,
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// The padded line of an [InsetRow], at least a button high: its [content],
/// then an optional [trailing] control and an optional chevron.
class InsetRowLine extends StatelessWidget {
  const InsetRowLine({
    super.key,
    required this.content,
    this.trailing,
    this.showChevron = false,
  });

  final List<Widget> content;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            ...content,
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
            if (showChevron) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              // The forward chevron (SF chevron.forward) mirrors in Arabic: it points to the
              // end (left), where the row leads.
              const Icon(
                ArrowIcons.forward,
                size: AppSizes.iconSmall,
                color: AppSemanticColors.borderControlBase,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
