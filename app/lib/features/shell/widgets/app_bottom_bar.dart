import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/theme/materials/glass_preferences.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

typedef _Tab = ({
  String labelKey,
  IconData icon,
  IconData unselectedIcon,
  String symbol,
  String selectedSymbol,
});

const List<_Tab> _tabs = <_Tab>[
  (
    labelKey: 'tab.today',
    icon: CupertinoIcons.house_fill,
    unselectedIcon: CupertinoIcons.house,
    symbol: 'house',
    selectedSymbol: 'house.fill',
  ),
  (
    labelKey: 'tab.plan',
    icon: Icons.medical_services,
    unselectedIcon: Icons.medical_services_outlined,
    symbol: 'cross.case',
    selectedSymbol: 'cross.case.fill',
  ),
  (
    labelKey: 'tab.record',
    icon: CupertinoIcons.square_list_fill,
    unselectedIcon: CupertinoIcons.square_list,
    symbol: 'list.bullet.rectangle',
    selectedSymbol: 'list.bullet.rectangle.fill',
  ),
  (
    labelKey: 'tab.circle',
    icon: CupertinoIcons.person_2_fill,
    unselectedIcon: CupertinoIcons.person_2,
    symbol: 'person.2',
    selectedSymbol: 'person.2.fill',
  ),
];

/// Bottom bar with four tabs. An iPhone on iOS 26 or later gets the native
/// glass tab bar; every other device gets a frosted Flutter bar styled as the
/// design system's TabBar: 64 high, a capsule, and a neutral selection. The add
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
    final Widget frosted = _FrostedTabBar(
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
        for (final _Tab tab in _tabs)
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

/// Renders the frosted tab bar element of app bottom bar.
class _FrostedTabBar extends StatelessWidget {
  const _FrostedTabBar({required this.currentIndex, required this.onTab});

  final int currentIndex;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: CrystalNavigationBar(
          currentIndex: currentIndex,
          onTap: onTab,
          height: AppSizes.tabBar,
          showLabels: true,
          marginR: EdgeInsets.zero,
          paddingR: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          borderRadius: AppSizes.tabBar / 2,
          blurSigma: GlassPreferences.opaqueOf(context)
              ? 0
              : AppGlass.blurSigma,
          backgroundColor: GlassPreferences.opaqueOf(context)
              ? scheme.surface
              : AppGlass.frostedSurface(scheme.surface),
          outlineBorderColor: GlassPreferences.opaqueOf(context)
              ? context.tokens.borderControl
              : scheme.surface,
          borderWidth: 1,
          selectedItemColor: AppSemanticColors.navigationSelected,
          unselectedItemColor: scheme.onSurfaceVariant,
          indicatorColor: AppSemanticColors.textSupporting,
          boxShadow: AppGlass.tabShadow(scheme.shadow),
          items: <CrystalNavigationBarItem>[
            for (final _Tab tab in _tabs)
              CrystalNavigationBarItem(
                icon: tab.icon,
                unselectedIcon: tab.unselectedIcon,
                label: context.tr(tab.labelKey),
              ),
          ],
        ),
      ),
    );
  }
}
