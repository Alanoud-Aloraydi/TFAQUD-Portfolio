import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A white rounded card with a light edge.
class SimplifiedCard extends StatelessWidget {
  const SimplifiedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SimplifiedStyle.pad),
    this.color = SimplifiedStyle.surface,
    this.side = const BorderSide(color: SimplifiedStyle.line),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final BorderSide side;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
      side: side,
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
