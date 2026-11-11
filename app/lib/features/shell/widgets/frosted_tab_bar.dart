import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_preferences.dart';
import 'package:app/core/theme/materials/tab_bar_style.dart';
import 'package:app/core/widgets/navigation/press_state_listener.dart';
import 'package:app/features/shell/widgets/frosted_tab_bar_body.dart';
import 'package:app/features/shell/widgets/frosted_tab_bar_colors.dart';
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
