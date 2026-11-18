import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/forms/tap_to_focus.dart';
import 'package:app/core/widgets/layout/inset_field_decoration.dart';
import 'package:app/core/widgets/layout/inset_row_error.dart';
import 'package:app/core/widgets/layout/inset_row_label.dart';
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
    builder: (FocusNode node) {
      final TextTheme text = Theme.of(context).textTheme;
      final bool multiline = maxLines > 1;
      final Widget field = TextField(
        controller: controller,
        focusNode: node,
        autofocus: autofocus,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: multiline ? TextInputAction.newline : textInputAction,
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
                            child: InsetRowLabel(label),
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
          if (errorText != null) InsetRowError(errorText!),
        ],
      );
    },
  );
}
