import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/widgets.dart';

export 'package:app/core/constants/icons/action_icons.dart';

/// Dates, times and places of the plans and the appointments.
abstract final class ScheduleIcons {
  /// A date. Phosphor `calendarBlank`.
  static const IconData calendar = IconData(
    0xe10a,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Add an appointment. Phosphor `calendarPlus`.
  static const IconData calendarPlus = IconData(
    0xe714,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// A time. Phosphor `clock`.
  static const IconData clock = IconData(
    0xe19a,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Grace time before a dose is missed. Phosphor `timer`.
  static const IconData timer = IconData(
    0xe492,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// A city or a place. Phosphor `mapPin`.
  static const IconData mapPin = IconData(
    0xe316,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );
}

/// The arrows and carets: back, forward and the ones that open and close a
/// list.
abstract final class ArrowIcons {
  /// Back. Points right in Arabic, as in the handoff. Phosphor `arrowLeft`.
  static const IconData back = IconData(
    0xe058,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
    matchTextDirection: true,
  );

  /// A row that opens a page. Points left in Arabic. Phosphor `caretRight`.
  static const IconData forward = IconData(
    0xe13a,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
    matchTextDirection: true,
  );

  /// Go on to the next page. Points left in Arabic. Phosphor `arrowRight`.
  static const IconData next = IconData(
    0xe06c,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
    matchTextDirection: true,
  );

  /// Opens a list or a card. Phosphor `caretDown`.
  static const IconData caretDown = IconData(
    0xe136,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Closes an open card. Phosphor `caretUp`.
  static const IconData caretUp = IconData(
    0xe13c,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// A button that opens a list of choices. Phosphor `caretUpDown`.
  static const IconData caretUpDown = IconData(
    0xe140,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );
}

/// Notices and what is done with a page: information, warnings, the bell, read
/// only, export and share.
abstract final class NoticeIcons {
  /// Information. Phosphor `info`.
  static const IconData info = IconData(
    0xe2ce,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Allergy or a warning. Phosphor `warning`.
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// An error under a field. Phosphor `warningCircle`.
  static const IconData warningCircle = IconData(
    0xe4e2,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Notifications. Phosphor `bell`.
  static const IconData bell = IconData(
    0xe0ce,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Read only. Phosphor `lockSimple`.
  static const IconData lock = IconData(
    0xe308,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Export. Phosphor `export`.
  static const IconData export = IconData(
    0xeaf0,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Share. Phosphor `shareNetwork`.
  static const IconData share = IconData(
    0xe408,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );
}

/// The home tab and the bottom bar's tabs, outline and filled.
abstract final class TabIcons {
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

/// The care itself: medicines, readings, the medical file and the emergency
/// card.
abstract final class CareIcons {
  /// A medicine. Phosphor `pill`.
  static const IconData pill = IconData(
    0xe700,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Blood sugar, blood type. Phosphor `drop`.
  static const IconData drop = IconData(
    0xe210,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Blood pressure, conditions, a reading now. Phosphor `heartbeat`.
  static const IconData heartbeat = IconData(
    0xe2ac,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Care. Phosphor `heart`.
  static const IconData heart = IconData(
    0xe2a8,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// The emergency card. Phosphor `firstAid`.
  static const IconData firstAid = IconData(
    0xe56e,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// The medical file, a visit sheet. Phosphor `fileText`.
  static const IconData fileText = IconData(
    0xe23a,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Add a measurement plan. Phosphor `listPlus`.
  static const IconData listPlus = IconData(
    0xe2f8,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Call the ambulance. Phosphor `siren`.
  static const IconData siren = IconData(
    0xe9b8,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );
}
