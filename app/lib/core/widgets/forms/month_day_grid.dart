import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The days of a month, 1 to [lastDay] (28: the days every month has, so a
/// monthly dose never moves), seven to a row, to choose one or more — the
/// same as the "Each" grid of a monthly repeat in Apple's Calendar.
///
/// A chosen day is filled and outlined more strongly, and screen readers
/// hear it as selected, so the choice never rests on colour alone. Each
/// day is at least [AppSizes.touch] high. [labelOf] gives what a screen
/// reader says for a day («اليوم 15 من الشهر»).
class MonthDayGrid extends StatelessWidget {
  const MonthDayGrid({
    super.key,
    required this.selected,
    required this.onTap,
    required this.labelOf,
  });

  final Set<int> selected;
  final ValueChanged<int> onTap;
  final String Function(int day) labelOf;

  static const int _columns = 7;

  /// The last day offered; February has no 29th in most years.
  static const int lastDay = 28;

  void _choose(int day) {
    HapticFeedback.selectionClick();
    onTap(day);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppTokens tokens = context.tokens;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cell =
            (constraints.maxWidth - AppSpacing.xs * (_columns - 1)) / _columns;
        final double side = cell < AppSizes.touch ? cell : AppSizes.touch;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (int day = 1; day <= lastDay; day++)
              SizedBox(
                width: cell,
                height: AppSizes.touch,
                // One node per day: its label, its state, and its tap, so
                // VoiceOver reads «يوم 15 من الشهر، محدد» and a double tap
                // chooses it.
                child: Semantics(
                  button: true,
                  selected: selected.contains(day),
                  label: labelOf(day),
                  onTap: () => _choose(day),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _choose(day),
                    child: Center(
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: CircleBorder(
                            side: BorderSide(
                              color: selected.contains(day)
                                  ? AppSemanticColors.actionPrimary
                                  : tokens.borderControl,
                              width: selected.contains(day)
                                  ? AppSizes.borderEmphasis
                                  : AppSizes.border,
                            ),
                          ),
                          color: selected.contains(day)
                              ? AppSemanticColors.selectedSurface
                              : AppSemanticColors.surfaceContent,
                        ),
                        child: SizedBox.square(
                          dimension: side,
                          child: Center(
                            child: Text(
                              '$day',
                              style: selected.contains(day)
                                  ? text.titleSmall
                                  : text.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
