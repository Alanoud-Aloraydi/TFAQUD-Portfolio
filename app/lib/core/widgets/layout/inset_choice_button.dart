import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
            const SizedBox(width: AppSpacing.xs),
            const Icon(AppIcons.caretUpDown, size: AppSizes.iconSmall),
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
