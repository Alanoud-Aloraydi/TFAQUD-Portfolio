import 'package:app/core/theme/materials/glass_style.dart';
import 'package:flutter/material.dart';

/// Soft scroll edge effect: the canvas fades in behind the top controls.
class TopBarScrollEdge extends StatelessWidget {
  const TopBarScrollEdge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppGlass.scrollEdge),
    );
  }
}
