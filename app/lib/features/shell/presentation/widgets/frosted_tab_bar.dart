import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/theme/materials/tab_bar_style.dart';
import 'package:app/core/widgets/navigation/press_state_listener.dart';
import 'package:app/features/shell/presentation/widgets/shell_tabs.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The bar for every device but an iPhone on iOS 26: transparent at rest, and
/// dark only while a finger is on it.
class FrostedTabBar extends StatelessWidget {
  const FrostedTabBar({
    super.key,
    required this.currentIndex,
    required this.onTab,
  });

  final int currentIndex;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: PressStateListener(builder: _animatedBar),
      ),
    );
  }

  Widget _animatedBar(BuildContext context, bool pressed) {
    final bool opaque = GlassPreferences.opaqueOf(context);
    final FrostedTabBarColors target = FrostedTabBarColors.of(
      Theme.of(context).colorScheme,
      pressed: pressed,
      opaque: opaque,
    );

    return TweenAnimationBuilder<FrostedTabBarColors>(
      tween: FrostedTabBarColorsTween(end: target),
      duration: AppTabBarStyle.transition,
      builder: (BuildContext context, FrostedTabBarColors now, _) =>
          FrostedTabBarBody(
            currentIndex: currentIndex,
            onTab: onTab,
            colors: now,
            opaque: opaque,
          ),
    );
  }
}

/// The tab bar drawn in one colour state; the parent animates the state.
class FrostedTabBarBody extends StatelessWidget {
  const FrostedTabBarBody({
    super.key,
    required this.currentIndex,
    required this.onTab,
    required this.colors,
    required this.opaque,
  });

  final int currentIndex;
  final ValueChanged<int> onTab;
  final FrostedTabBarColors colors;
  final bool opaque;

  @override
  Widget build(BuildContext context) => CrystalNavigationBar(
    currentIndex: currentIndex,
    onTap: onTab,
    height: AppSizes.tabBar,
    showLabels: true,
    marginR: EdgeInsets.zero,
    paddingR: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    borderRadius: AppSizes.tabBar / 2,
    blurSigma: opaque ? 0 : AppGlass.blurSigma,
    backgroundColor: colors.fill,
    outlineBorderColor: opaque ? context.tokens.borderControl : colors.fill,
    borderWidth: 1,
    selectedItemColor: colors.selected,
    unselectedItemColor: colors.unselected,
    indicatorColor: colors.unselected,
    boxShadow: colors.shadow(Theme.of(context).colorScheme.shadow),
    items: <CrystalNavigationBarItem>[
      for (final ShellTab tab in shellTabs)
        CrystalNavigationBarItem(
          icon: tab.icon,
          unselectedIcon: tab.unselectedIcon,
          label: context.tr(tab.labelKey),
        ),
    ],
  );
}

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
