import 'package:app/core/constants/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A tab of the bottom bar: its label, its icons (filled while selected,
/// outlined otherwise), and the names of the same drawings in the iOS
/// asset catalog for the native bar ([symbol], [selectedSymbol]). They are
/// images, not system symbols: iOS fills every system symbol of a tab bar.
typedef ShellTab = ({
  String labelKey,
  IconData icon,
  IconData unselectedIcon,
  String symbol,
  String selectedSymbol,
});

const List<ShellTab> shellTabs = <ShellTab>[
  (
    labelKey: 'tab.today',
    icon: AppIcons.tabTodayFill,
    unselectedIcon: AppIcons.tabToday,
    symbol: 'tab_today',
    selectedSymbol: 'tab_today_fill',
  ),
  (
    labelKey: 'tab.plan',
    icon: AppIcons.tabPlanFill,
    unselectedIcon: AppIcons.tabPlan,
    symbol: 'tab_plan',
    selectedSymbol: 'tab_plan_fill',
  ),
  (
    labelKey: 'tab.record',
    icon: AppIcons.tabRecordFill,
    unselectedIcon: AppIcons.tabRecord,
    symbol: 'tab_record',
    selectedSymbol: 'tab_record_fill',
  ),
  (
    labelKey: 'tab.circle',
    icon: AppIcons.tabCircleFill,
    unselectedIcon: AppIcons.users,
    symbol: 'tab_circle',
    selectedSymbol: 'tab_circle_fill',
  ),
];
