import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Round glass add button, floated above the bottom bar by the shell.
/// Neutral glass with an ink plus; a green tint is still under study.
/// A null [onPressed] keeps it visible but dimmed and inert.
class GlassAddButton extends StatelessWidget {
  const GlassAddButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: AppGlass.addButtonSize,
        child: GlassSurface(
          borderRadius: BorderRadius.circular(AppGlass.addButtonSize / 2),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Center(
                child: Icon(
                  CupertinoIcons.add,
                  size: AppSizes.iconAction,
                  color: enabled
                      ? AppSemanticColors.textPrimary
                      : AppGlass.disabledIcon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
