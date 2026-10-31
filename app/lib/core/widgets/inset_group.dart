import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS inset grouped section, as in Settings and Health: a header above a
/// white card of rows divided by inset lines, and an optional footer.
///
/// The card is radius-l; rows inside keep 16 side padding, so anything
/// rounded inside a row is radius-s (28 − 16).
class InsetGroup extends StatelessWidget {
  const InsetGroup({
    super.key,
    required this.children,
    this.header,
    this.headerAction,
    this.footer,
  });

  final List<Widget> children;
  final String? header;

  /// A small action at the end of the header, such as a delete button.
  final Widget? headerAction;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final ShapeBorder shape = AppRadius.shape(AppRadius.l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (header != null || headerAction != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      header ?? '',
                      style: text.titleSmall?.copyWith(color: tokens.textSecondary),
                    ),
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            color: AppColors.surface,
            shadows: AppGlass.cardShadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1, indent: AppSpacing.lg),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: AppSpacing.lg,
              top: AppSpacing.sm,
            ),
            child: Text(footer!, style: text.bodySmall),
          ),
      ],
    );
  }
}

/// One tappable row: the label at the start, the value (or a placeholder) at
/// the end, and an optional chevron. At least 50 high, so it is easy to tap.
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
  });

  final String label;

  /// The chosen value, in ink.
  final String? value;

  /// Shown when there is no value, in the secondary text color.
  final String? placeholder;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final FocusNode? focusNode;

  /// For an action row such as «إضافة موعد».
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final String? shown = value ?? placeholder;
    return InkWell(
      onTap: onTap,
      focusNode: focusNode,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                IconTheme.merge(
                  data: IconThemeData(
                    color: labelColor ?? AppColors.ink,
                    size: AppSizes.iconSmall,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Flexible(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(color: labelColor),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: shown == null
                    ? const SizedBox.shrink()
                    : Text(
                        shown,
                        textAlign: TextAlign.end,
                        style: text.bodyLarge?.copyWith(
                          color: value == null ? tokens.textSecondary : AppColors.ink,
                        ),
                      ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
              if (showChevron) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                // chevron_right mirrors in Arabic: it points to the end.
                const Icon(Icons.chevron_right, size: AppSizes.iconSmall, color: AppColors.stone),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with its label at the start and a borderless text field after it.
/// The card is the field's boundary, as in iOS forms. A hint and an error
/// show under the row; the error also has an icon, so it is not color alone.
class InsetTextRow extends StatelessWidget {
  const InsetTextRow({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// The most characters the user can type. No counter is shown.
  final int? maxLength;
  final int maxLines;
  final TextInputAction textInputAction;

  /// A small control after the field, such as a unit button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final bool multiline = maxLines > 1;
    final Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: multiline ? TextInputAction.newline : textInputAction,
      maxLines: maxLines,
      minLines: 1,
      textAlign: multiline ? TextAlign.start : TextAlign.end,
      style: text.bodyLarge,
      inputFormatters: <TextInputFormatter>[
        ...?inputFormatters,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        hintText: hint,
        filled: false,
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The visible label and the field merge into one node, so
          // VoiceOver reads the label with the field.
          if (multiline)
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(label, style: text.bodyLarge),
                  field,
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.button),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: MergeSemantics(
                      child: Row(
                        children: <Widget>[
                          Text(label, style: text.bodyLarge),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: field),
                        ],
                      ),
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    trailing!,
                  ],
                ],
              ),
            ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.error_outline, size: 18, color: tokens.error),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: text.bodySmall?.copyWith(color: tokens.errorText),
                    ),
                  ),
                ],
              ),
            )
          else if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(helperText!, style: text.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// A small button inside a row that shows a choice and opens [onPressed],
/// such as the strength unit «ملغ». At least 44 high.
class InsetChoiceButton extends StatelessWidget {
  const InsetChoiceButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;

  /// What VoiceOver reads, for example «وحدة التركيز: ملغ».
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    // The button's own label is only the unit; VoiceOver gets the full
    // label, and keeps the tap action.
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label),
            const SizedBox(width: 2),
            const Icon(Icons.unfold_more, size: 18),
          ],
        ),
      ),
    );
  }
}

/// iOS action sheet to pick one option. The current option is bold.
/// Returns null when the person cancels.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T option) labelOf,
  T? selected,
}) {
  const TextStyle style = TextStyle(fontFamily: AppTextTheme.fontFamily);
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (BuildContext sheetContext) => CupertinoActionSheet(
      title: Text(title, style: style),
      actions: <Widget>[
        for (final T option in options)
          CupertinoActionSheetAction(
            isDefaultAction: option == selected,
            onPressed: () => Navigator.pop(sheetContext, option),
            child: Text(labelOf(option), style: style),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(sheetContext),
        child: Text(sheetContext.tr('common.cancel'), style: style),
      ),
    ),
  );
}
