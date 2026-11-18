import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/widgets.dart';

/// The home tab and the bottom bar's tabs, outline and filled.
abstract final class TabIcons {
  /// Tab «اليوم». Phosphor `houseSimple`.
  static const IconData house = IconData(
    0xe2c6,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  // The bottom bar: each tab's outline icon, and its filled one while the tab
  // is selected. The native bar on iOS shows the same drawings
  // (ios/Runner/Assets.xcassets/tab_*.imageset), because iOS draws its own
  // symbols filled in a tab bar whether selected or not.

  /// «اليوم». Phosphor `house`.
  static const IconData tabToday = IconData(
    0xe2c2,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// «اليوم», selected. Phosphor `house` fill.
  static const IconData tabTodayFill = IconData(
    0xe2c2,
    fontFamily: phosphorFillFamily,
    fontPackage: phosphorPackage,
  );

  /// «الخطة». Phosphor `firstAidKit`.
  static const IconData tabPlan = IconData(
    0xe570,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// «الخطة», selected. Phosphor `firstAidKit` fill.
  static const IconData tabPlanFill = IconData(
    0xe570,
    fontFamily: phosphorFillFamily,
    fontPackage: phosphorPackage,
  );

  /// «السجل». Phosphor `notebook`.
  static const IconData tabRecord = IconData(
    0xe34e,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// «السجل», selected. Phosphor `notebook` fill.
  static const IconData tabRecordFill = IconData(
    0xe34e,
    fontFamily: phosphorFillFamily,
    fontPackage: phosphorPackage,
  );

  /// «الدائرة», selected. Phosphor `users` fill; `PeopleIcons.users` is
  /// its outline.
  static const IconData tabCircleFill = IconData(
    0xe4d6,
    fontFamily: phosphorFillFamily,
    fontPackage: phosphorPackage,
  );
}
