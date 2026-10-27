import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell shown on every tab: top bar, the current tab, bottom bar, and the
/// docked add button.
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
      floatingActionButton: FloatingActionButton(
        tooltip: context.tr('tab.add'),
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
