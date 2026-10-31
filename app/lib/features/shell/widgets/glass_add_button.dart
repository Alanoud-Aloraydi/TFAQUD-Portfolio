import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/glass.dart';
import 'package:flutter/material.dart';

/// Opacity of the white fill of the frosted shell surfaces: the bottom bar and
/// the add button share it so they read as one material (design system glass
/// recipe; a starting value to test on a device).
const double kFrostedAlpha = AppGlass.tintAlpha;

/// Blur behind the frosted shell surfaces.
const double kFrostedBlurSigma = AppGlass.blurSigma;

const double _size = 56;

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
        dimension: _size,
        child: GlassSurface(
          borderRadius: BorderRadius.circular(_size / 2),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Center(
                child: Icon(
                  Icons.add,
                  size: 28,
                  color: enabled
                      ? AppColors.ink
                      : AppColors.slate.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
