import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One option of a single-choice question (who the circle is for, the mode
/// of the patient's app): an icon, a title, a hint and a radio mark. Every
/// option and what it means stay on the screen. The whole card is the tap target, and
/// screen readers hear it as a checked or unchecked option of one group.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: AppSemanticColors.surfaceContent,
        clipBehavior: Clip.antiAlias,
        shape: AppRadius.shape(
          AppRadius.card,
          side: BorderSide(
            color: selected
                ? AppSemanticColors.textPrimary
                : AppSemanticColors.borderSubtle,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                Container(
                  width: AppSizes.avatar,
                  height: AppSizes.avatar,
                  decoration: const BoxDecoration(
                    color: AppSemanticColors.selectedSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AppSizes.iconSmall,
                    color: AppSemanticColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: text.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(hint, style: text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _RadioMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The radio mark at the end of a [ChoiceCard]: a ring, filled when
/// selected.
class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppSemanticColors.textPrimary
              : AppSemanticColors.borderControlBase,
          width: AppSizes.borderEmphasis,
        ),
      ),
      child: selected
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppSemanticColors.textPrimary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
