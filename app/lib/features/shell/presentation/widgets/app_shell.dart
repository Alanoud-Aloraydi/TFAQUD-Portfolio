import 'package:app/app/services/native_glass.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/features/shell/presentation/widgets/frosted_tab_bar.dart';
import 'package:app/features/shell/presentation/widgets/shell_tabs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

/// Shell shown on every tab: top bar, the current tab, bottom bar, and the
/// add button floating above that bar.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.topBar,
    required this.onAdd,
    this.body,
  });

  final StatefulNavigationShell navigationShell;
  final PreferredSizeWidget topBar;
  final VoidCallback? onAdd;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Content scrolls under the glass controls at the top and the tab bar
      // at the bottom, so the glass has something to show. Lists add the
      // bars' heights to their padding (ScrollInsets).
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: topBar,
      body: body ?? navigationShell,
      // On iOS 26 the native tab bar draws the add button beside itself.
      floatingActionButton: NativeGlass.isSupported
          ? null
          : GlassAddButton(tooltip: context.tr('tab.add'), onPressed: onAdd),
      bottomNavigationBar: AppBottomBar(
        onAdd: onAdd,
        currentIndex: navigationShell.currentIndex,
        onTab: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Bottom bar with four tabs. An iPhone on iOS 26 or later gets the native
/// glass tab bar, which iOS draws itself; every other device gets the
/// [FrostedTabBar], transparent at rest and dark while pressed. The add
/// button is not part of it: the shell floats it above the bar.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTab,
    this.onAdd,
  });

  /// Selected branch: 0 today, 1 plan, 2 record, 3 circle.
  final int currentIndex;
  final ValueChanged<int> onTab;

  /// The add action. On the native bar it becomes the round glass button
  /// beside the tabs; elsewhere the shell shows its own add button.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? add = onAdd;
    final Widget frosted = FrostedTabBar(
      currentIndex: currentIndex,
      onTab: onTab,
    );
    // The native view cannot exist on the web, so it is never built there.
    if (kIsWeb) return frosted;

    return NativeGlassNavBar(
      currentIndex: currentIndex,
      onTap: onTab,
      tintColor: AppSemanticColors.navigationSelected,
      actionButton: add == null
          ? null
          : TabBarActionButton(symbol: 'plus', onTap: add),
      tabs: <NativeGlassNavBarItem>[
        for (final ShellTab tab in shellTabs)
          NativeGlassNavBarItem(
            label: context.tr(tab.labelKey),
            symbol: tab.symbol,
            selectedSymbol: tab.selectedSymbol,
          ),
      ],
      fallback: frosted,
    );
  }
}

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
            child: Semantics(
              button: true,
              enabled: enabled,
              label: spoken(tooltip),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Center(
                  child: Icon(
                    ActionIcons.plus,
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
      ),
    );
  }
}
