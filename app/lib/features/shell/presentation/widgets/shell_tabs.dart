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
    icon: TabIcons.tabTodayFill,
    unselectedIcon: TabIcons.tabToday,
    symbol: 'tab_today',
    selectedSymbol: 'tab_today_fill',
  ),
  (
    labelKey: 'tab.plan',
    icon: TabIcons.tabPlanFill,
    unselectedIcon: TabIcons.tabPlan,
    symbol: 'tab_plan',
    selectedSymbol: 'tab_plan_fill',
  ),
  (
    labelKey: 'tab.record',
    icon: TabIcons.tabRecordFill,
    unselectedIcon: TabIcons.tabRecord,
    symbol: 'tab_record',
    selectedSymbol: 'tab_record_fill',
  ),
  (
    labelKey: 'tab.circle',
    icon: TabIcons.tabCircleFill,
    unselectedIcon: PeopleIcons.users,
    symbol: 'tab_circle',
    selectedSymbol: 'tab_circle_fill',
  ),
];
