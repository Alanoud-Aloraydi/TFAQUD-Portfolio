import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS inset grouped section, as in Settings and Health (design system
/// FormGroup): a header above a white card of rows divided by inset lines,
/// and an optional footer.
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

/// The small grey label at the start of a form row. It reads like a hint, so
/// the value or the typed text, set larger in ink, is what stands out. Every
/// label has the same column width, so values line up from row to row.
class _RowLabel extends StatelessWidget {
  const _RowLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.formLabel,
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// An error under a form row, lined up with the value column: an icon and a
/// short message, so it is not color alone.
class _RowError extends StatelessWidget {
  const _RowError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg + AppSizes.formLabel + AppSpacing.md,
        end: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: tokens.error),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.errorText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable row. With a [leading] icon it is an action row, such as
/// «إضافة موعد جرعة»: the icon and the label in ink. Otherwise it is a field
/// row: the small label in its column, then the value (or a placeholder)
/// starting right after it, and an optional chevron at the end. At least 50
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
    final TextTheme text = Theme.of(context).textTheme;
    final String? shown = value ?? placeholder;
    final List<Widget> content = labelOnly
        ? <Widget>[Expanded(child: Text(label, style: text.bodyLarge))]
        : leading != null
        ? <Widget>[
            IconTheme.merge(
              data: IconThemeData(
                color: labelColor ?? AppColors.ink,
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
            _RowLabel(label),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: shown == null
                  ? const SizedBox.shrink()
                  : Text(
                      shown,
                      style: value == null
                          ? text.bodyMedium?.copyWith(color: AppColors.stone)
                          : text.bodyLarge,
                    ),
            ),
          ];
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
              ConstrainedBox(
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
                        // chevron_right mirrors in Arabic: it points to the
                        // end (left), where the row leads.
                        const Icon(
                          Icons.chevron_right,
                          size: AppSizes.iconSmall,
                          color: AppColors.stone,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (errorText != null) _RowError(errorText!),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row that cannot be tapped, with the small label in its column and any
/// widget as its value, such as a name read from the account.
class InsetFieldRow extends StatelessWidget {
  const InsetFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              _RowLabel(label),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: child),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with the small label in its column and a borderless text field
/// after it. The card is the field's boundary, as in iOS forms. Typed text
/// starts on the right, after the label, as Arabic is read. A short [hint]
/// inside the field says what to type; it replaces any line under the row.
/// An error shows under the row, with an icon, so it is not color alone.
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

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool multiline = maxLines > 1;
    final Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: multiline ? TextInputAction.newline : textInputAction,
      maxLines: maxLines,
      minLines: 1,
      // Arabic is read from the right: the text starts after the label.
      textAlign: TextAlign.start,
      style: text.bodyLarge,
      inputFormatters: <TextInputFormatter>[
        ...?inputFormatters,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.stone),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: multiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: <Widget>[
                // The visible label and the field merge into one node, so
                // VoiceOver reads the label with the field.
                Expanded(
                  child: MergeSemantics(
                    child: Row(
                      crossAxisAlignment: multiline
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                            top: multiline ? AppSpacing.md : 0,
                          ),
                          child: _RowLabel(label),
                        ),
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
        ),
        if (errorText != null) _RowError(errorText!),
      ],
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

/// A sheet to pick several options, as Apple Health picks the days of a
/// medicine: a grouped list with a check mark on each chosen row, and the
/// confirm button. Confirm stays off until at least [minimum] are chosen.
/// Returns null when the sheet is closed without confirming.
Future<Set<T>?> showChecklistSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T option) labelOf,
  required Set<T> selected,
  int minimum = 1,
}) {
  return showModalBottomSheet<Set<T>>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final Set<T> chosen = <T>{...selected};
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return PickerSheetFrame(
            title: title,
            confirmLabel: context.tr('common.confirm'),
            onConfirm: chosen.length < minimum
                ? null
                : () => Navigator.pop(context, chosen),
            child: InsetGroup(
              children: <Widget>[
                for (final T option in options)
                  Semantics(
                    selected: chosen.contains(option),
                    child: InsetRow(
                      label: labelOf(option),
                      labelOnly: true,
                      trailing: chosen.contains(option)
                          ? const Icon(
                              Icons.check,
                              size: AppSizes.iconSmall,
                              color: AppColors.ink,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (!chosen.remove(option)) chosen.add(option);
                        });
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
