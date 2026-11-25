import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/inset_row_line.dart';
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
