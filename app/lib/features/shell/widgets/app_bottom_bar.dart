import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/shell/widgets/frosted_tab_bar.dart';
import 'package:app/features/shell/widgets/shell_tabs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

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
