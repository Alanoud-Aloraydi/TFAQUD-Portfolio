import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Opacity of the white fill of the frosted shell surfaces: the bottom bar and
/// the add button share it so they read as one material.
const double kFrostedAlpha = 0.7;

/// Blur behind the frosted shell surfaces.
const double kFrostedBlurSigma = 20;

const double _size = 56;

/// Round frosted add button, floated above the bottom bar by the shell.
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: kFrostedBlurSigma,
            sigmaY: kFrostedBlurSigma,
          ),
          child: Material(
            color: scheme.surface.withValues(alpha: kFrostedAlpha),
            shape: CircleBorder(side: BorderSide(color: scheme.surface)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Icon(
                  Icons.add,
                  color: enabled
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
