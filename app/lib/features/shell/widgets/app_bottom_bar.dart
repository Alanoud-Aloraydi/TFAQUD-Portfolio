import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/shell/widgets/glass_add_button.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

typedef _Tab = ({
  String labelKey,
  IconData icon,
  IconData outlinedIcon,
  String symbol,
  String selectedSymbol,
});

const List<_Tab> _tabs = <_Tab>[
  (
    labelKey: 'tab.today',
    icon: Icons.wb_sunny,
    outlinedIcon: Icons.wb_sunny_outlined,
    symbol: 'sun.max',
    selectedSymbol: 'sun.max.fill',
  ),
  (
    labelKey: 'tab.plan',
    icon: Icons.description,
    outlinedIcon: Icons.description_outlined,
    symbol: 'doc.text',
    selectedSymbol: 'doc.text.fill',
  ),
  (
    labelKey: 'tab.record',
    icon: Icons.book,
    outlinedIcon: Icons.book_outlined,
    symbol: 'book',
    selectedSymbol: 'book.fill',
  ),
  (
    labelKey: 'tab.circle',
    icon: Icons.people,
    outlinedIcon: Icons.people_outline,
    symbol: 'person.2',
    selectedSymbol: 'person.2.fill',
  ),
];

const double _barHeight = 64;
const double _barRadius = 32;

/// Bottom bar with four tabs. An iPhone on iOS 26 or later gets the native
/// glass tab bar; every other device gets a frosted Flutter bar. The add
/// button is not part of it: the shell floats it above the bar.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTab,
  });

  /// Selected branch: 0 today, 1 plan, 2 record, 3 circle.
  final int currentIndex;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final Widget frosted = _FrostedTabBar(
      currentIndex: currentIndex,
      onTab: onTab,
    );
    // The native view cannot exist on the web, so it is never built there.
    if (kIsWeb) return frosted;

    return NativeGlassNavBar(
      currentIndex: currentIndex,
      onTap: onTab,
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
          height: _barHeight,
          showLabels: true,
          marginR: EdgeInsets.zero,
          paddingR: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          borderRadius: _barRadius,
          blurSigma: kFrostedBlurSigma,
          backgroundColor: scheme.surface.withValues(alpha: kFrostedAlpha),
          outlineBorderColor: scheme.surface,
          borderWidth: 1,
          selectedItemColor: scheme.primary,
          unselectedItemColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary.withValues(alpha: 0.12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          items: <CrystalNavigationBarItem>[
            for (final _Tab tab in _tabs)
              CrystalNavigationBarItem(
                icon: tab.icon,
                unselectedIcon: tab.outlinedIcon,
                label: context.tr(tab.labelKey),
              ),
          ],
        ),
      ),
    );
  }
}
