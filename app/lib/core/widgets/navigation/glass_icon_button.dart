import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:flutter/material.dart';

/// Round glass button of the top controls: account and notifications.
/// [tooltip] is also what VoiceOver reads.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = AppSizes.glassButton,
  });

  final String tooltip;
  final Widget icon;

  /// Null keeps the button visible but inert.
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(size / 2),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: icon,
          iconSize: AppSizes.icon,
          color: AppSemanticColors.textPrimary,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tight(Size.square(size)),
          style: IconButton.styleFrom(shape: const CircleBorder()),
        ),
      ),
    );
  }
}
