import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlassMenuRow extends StatelessWidget {
  const GlassMenuRow({super.key, required this.entry, required this.height});

  final GlassMenuEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final IconData? icon = entry.selected ? AppIcons.check : entry.icon;
    return Semantics(
      button: true,
      selected: entry.selected,
      child: SizedBox(
        height: height,
        child: Padding(
          // 8 inside the 28 panel: the pressed highlight is radius 20, so the
          // two corners are concentric.
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(entry.value);
            },
            customBorder: AppRadius.shape(AppRadius.m),
            highlightColor: AppEffects.interactionOverlay,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: AppSizes.icon,
                    child: icon == null
                        ? null
                        : Icon(
                            icon,
                            size: AppSizes.iconSmall,
                            color: AppSemanticColors.textPrimary,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: entry.selected
                            ? AppTextTheme.semibold
                            : AppTextTheme.regular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
