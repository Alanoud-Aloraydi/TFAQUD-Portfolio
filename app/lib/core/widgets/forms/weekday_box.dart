import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// One day of the weekday selector: a round chip with the day's letter,
/// drawn as the app's other chips are (an outline, the green fill when it
/// is on), 44 points high. Seven of them share the row's width, so on a
/// narrow phone a day is a little narrower than high.
class WeekdayBox extends StatelessWidget {
  const WeekdayBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    onTap: onTap,
    label: semanticLabel ?? label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        height: AppSizes.touch,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: selected
                ? AppSemanticColors.selectedSurface
                : AppSemanticColors.surfaceContent,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? AppSemanticColors.textPrimary
                    : context.tokens.borderControl,
              ),
            ),
          ),
          child: Center(
            child: Text(label, style: Theme.of(context).chipTheme.labelStyle),
          ),
        ),
      ),
    ),
  );
}
