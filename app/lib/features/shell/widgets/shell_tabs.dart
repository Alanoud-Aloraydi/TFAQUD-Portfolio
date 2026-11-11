import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
