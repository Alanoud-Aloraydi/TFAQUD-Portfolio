import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/features/shell/widgets/frosted_tab_bar_colors.dart';
import 'package:app/features/shell/widgets/shell_tabs.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
