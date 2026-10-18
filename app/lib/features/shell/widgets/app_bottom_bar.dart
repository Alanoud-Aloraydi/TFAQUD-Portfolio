import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Bottom bar with four tabs. The add button is not part of it: the shell
/// docks a floating action button at the center.
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<({IconData icon, String label})> tabs = <({IconData icon, String label})>[
      (icon: Icons.wb_sunny_outlined, label: context.tr('tab.today')),
      (icon: Icons.description_outlined, label: context.tr('tab.plan')),
      (icon: Icons.book_outlined, label: context.tr('tab.record')),
      (icon: Icons.people_outline, label: context.tr('tab.circle')),
    ];

    return CurvedNavigationBar(
      index: currentIndex,
      color: scheme.surface,
      backgroundColor: theme.scaffoldBackgroundColor,
      buttonBackgroundColor: scheme.primaryContainer,
      onTap: onTab,
      items: <Widget>[
        for (int i = 0; i < tabs.length; i++)
          _TabItem(
            icon: tabs[i].icon,
            label: tabs[i].label,
            selected: i == currentIndex,
          ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
