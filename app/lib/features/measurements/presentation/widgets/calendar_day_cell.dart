import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// One day of the month calendar: its number, a dot when it has readings
/// (amber when any is outside the target), a frame when selected or today.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.count,
    required this.outside,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final int count;
  final bool outside;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  static const double _dot = 5;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$day · $count',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: Container(
          height: AppSizes.touch,
          decoration: BoxDecoration(
            color: selected
                ? AppSemanticColors.selectedSurface
                : outside
                ? AppSemanticColors.surfaceAttention
                : AppSemanticColors.surfaceContent,
            borderRadius: BorderRadius.circular(AppRadius.s),
            border: Border.all(
              color: selected || isToday
                  ? AppSemanticColors.textPrimary
                  : AppSemanticColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('$day', style: Theme.of(context).textTheme.labelSmall),
              if (count > 0)
                Container(
                  width: _dot,
                  height: _dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: outside
                        ? AppSemanticColors.statusWarning
                        : AppSemanticColors.statusSuccess,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
