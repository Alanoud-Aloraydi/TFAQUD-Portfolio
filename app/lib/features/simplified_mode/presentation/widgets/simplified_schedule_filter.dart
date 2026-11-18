import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// One kind to filter the schedule by: a pill, dark while it is the one
/// chosen.
class SimplifiedScheduleFilter extends StatelessWidget {
  const SimplifiedScheduleFilter({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: SimplifiedStyle.touch),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? SimplifiedColors.ink : SimplifiedColors.clear,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SimplifiedColors.control, width: 1.5),
          ),
          child: Text(
            label,
            style: SimplifiedStyle.head(
              SimplifiedStyle.caption,
              color: selected ? SimplifiedColors.surface : SimplifiedColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
