import 'package:app/core/widgets/overlays/glass_menu_blur.dart';
import 'package:flutter/material.dart';

/// The control's own content, drawn over the opening menu and fading and
/// blurring away as the menu grows; [fade] is its opacity.
class GlassMenuAnchorLayer extends StatelessWidget {
  const GlassMenuAnchorLayer({
    super.key,
    required this.fade,
    required this.content,
  });

  final double fade;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: fade,
          child: glassMenuBlurred((1 - fade) * 6, Center(child: content)),
        ),
      ),
    );
  }
}
