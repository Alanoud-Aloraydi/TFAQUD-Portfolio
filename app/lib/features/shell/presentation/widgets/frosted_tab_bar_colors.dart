import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/theme/materials/tab_bar_style.dart';
import 'package:flutter/material.dart';

/// Fill and foreground colours of the tab bar for one press state.
class FrostedTabBarColors {
  const FrostedTabBarColors({
    required this.fill,
    required this.selected,
    required this.unselected,
  });

  /// [opaque] keeps a solid surface at rest for Reduce Transparency and
  /// Increase Contrast; the pressed look is the same either way.
  factory FrostedTabBarColors.of(
    ColorScheme scheme, {
    required bool pressed,
    required bool opaque,
  }) {
    if (pressed) {
      return const FrostedTabBarColors(
        fill: AppTabBarStyle.pressedFill,
        selected: AppTabBarStyle.pressedForeground,
        unselected: AppTabBarStyle.pressedMutedForeground,
      );
    }
    return FrostedTabBarColors(
      fill: opaque ? scheme.surface : AppTabBarStyle.restFill,
      selected: AppSemanticColors.navigationSelected,
      unselected: scheme.onSurfaceVariant,
    );
  }

  final Color fill;
  final Color selected;
  final Color unselected;

  /// The shadow follows the fill, so a transparent bar casts none.
  List<BoxShadow> shadow(Color shadowColor) =>
      fill.a == 0 ? const <BoxShadow>[] : AppGlass.tabShadow(shadowColor);
}

/// Blends two colour states, so a press fades in and out.
class FrostedTabBarColorsTween extends Tween<FrostedTabBarColors> {
  FrostedTabBarColorsTween({super.end});

  @override
  FrostedTabBarColors lerp(double t) {
    final FrostedTabBarColors from = begin ?? end!;
    final FrostedTabBarColors to = end!;
    return FrostedTabBarColors(
      fill: Color.lerp(from.fill, to.fill, t)!,
      selected: Color.lerp(from.selected, to.selected, t)!,
      unselected: Color.lerp(from.unselected, to.unselected, t)!,
    );
  }
}
