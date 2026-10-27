import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:app/features/shell/widgets/glass_add_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      appBar: topBar,
      body: body ?? navigationShell,
      floatingActionButton: GlassAddButton(
        tooltip: context.tr('tab.add'),
        onPressed: onAdd,
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTab: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
