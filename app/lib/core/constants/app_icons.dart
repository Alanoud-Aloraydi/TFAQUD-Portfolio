import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

/// App icons use Phosphor regular except the shared iOS edit pencil.
/// Phosphor icons follow the handoff
/// (package `phosphor_flutter`, which brings the font).
///
/// The handoff draws them as they are, not mirrored, on its Arabic pages.
/// `PhosphorIconsRegular` mirrors every icon in Arabic, so the icons are
/// declared here with the same font and code points and no mirroring.
/// Only the arrows that mean a direction ([back], [forward]) follow the
/// reading direction. Code points come from phosphor_flutter 2.1.0, whose
/// code points are stable.
abstract class AppIcons {
  AppIcons._();

  static const String _family = 'PhosphorRegular';
  static const String _fillFamily = 'PhosphorFill';
  static const String _package = 'phosphor_flutter';

  /// Back. Points right in Arabic, as in the handoff. Phosphor `arrowLeft`.
  static const IconData back = IconData(
    0xe058,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// A row that opens a page. Points left in Arabic. Phosphor `caretRight`.
  static const IconData forward = IconData(
    0xe13a,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// Go on to the next page. Points left in Arabic. Phosphor `arrowRight`.
  static const IconData next = IconData(
    0xe06c,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// Opens a list or a card. Phosphor `caretDown`.
  static const IconData caretDown = IconData(
    0xe136,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Closes an open card. Phosphor `caretUp`.
  static const IconData caretUp = IconData(
    0xe13c,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A button that opens a list of choices. Phosphor `caretUpDown`.
  static const IconData caretUpDown = IconData(
    0xe140,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Add. Phosphor `plus`.
  static const IconData plus = IconData(
    0xe3d4,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Add a row inside a form. Phosphor `plusCircle`.
  static const IconData plusCircle = IconData(
    0xe3d6,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Less (stepper). Phosphor `minus`.
  static const IconData minus = IconData(
    0xe32a,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Chosen. Phosphor `check`.
  static const IconData check = IconData(
    0xe182,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Taken. Phosphor `checkCircle`.
  static const IconData checkCircle = IconData(
    0xe184,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Close or cancel. Phosphor `x`.
  static const IconData x = IconData(
    0xe4f6,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Delete. Phosphor `trash`.
  static const IconData trash = IconData(
    0xe4a6,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// The edit pencil used throughout the app.
  static const IconData pencil = CupertinoIcons.pencil;

  /// Information. Phosphor `info`.
  static const IconData info = IconData(
    0xe2ce,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Allergy or a warning. Phosphor `warning`.
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// An error under a field. Phosphor `warningCircle`.
  static const IconData warningCircle = IconData(
    0xe4e2,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Notifications. Phosphor `bell`.
  static const IconData bell = IconData(
    0xe0ce,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Search. Phosphor `magnifyingGlass`.
  static const IconData search = IconData(
    0xe30c,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A medicine. Phosphor `pill`.
  static const IconData pill = IconData(
    0xe700,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Blood sugar, blood type. Phosphor `drop`.
  static const IconData drop = IconData(
    0xe210,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Blood pressure, conditions, a reading now. Phosphor `heartbeat`.
  static const IconData heartbeat = IconData(
    0xe2ac,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Care. Phosphor `heart`.
  static const IconData heart = IconData(
    0xe2a8,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A date. Phosphor `calendarBlank`.
  static const IconData calendar = IconData(
    0xe10a,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Add an appointment. Phosphor `calendarPlus`.
  static const IconData calendarPlus = IconData(
    0xe714,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A time. Phosphor `clock`.
  static const IconData clock = IconData(
    0xe19a,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Grace time before a dose is missed. Phosphor `timer`.
  static const IconData timer = IconData(
    0xe492,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A skipped dose. Phosphor `prohibit`.
  static const IconData prohibit = IconData(
    0xe3de,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A city or a place. Phosphor `mapPin`.
  static const IconData mapPin = IconData(
    0xe316,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Add a measurement plan. Phosphor `listPlus`.
  static const IconData listPlus = IconData(
    0xe2f8,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Export. Phosphor `export`.
  static const IconData export = IconData(
    0xeaf0,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Share. Phosphor `shareNetwork`.
  static const IconData share = IconData(
    0xe408,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// The medical file, a visit sheet. Phosphor `fileText`.
  static const IconData fileText = IconData(
    0xe23a,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// The emergency card. Phosphor `firstAid`.
  static const IconData firstAid = IconData(
    0xe56e,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// «مدير». Phosphor `crown`.
  static const IconData crown = IconData(
    0xe614,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A person, «صاحب الملف». Phosphor `user`.
  static const IconData user = IconData(
    0xe4c2,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// The circle. Phosphor `users`.
  static const IconData users = IconData(
    0xe4d6,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Add a member. Phosphor `userPlus`.
  static const IconData userPlus = IconData(
    0xe4d0,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// A pending invitation. Phosphor `hourglassMedium`.
  static const IconData hourglass = IconData(
    0xe2b8,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Send an invitation. Phosphor `paperPlaneTilt`.
  static const IconData paperPlane = IconData(
    0xe398,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Leave the circle, sign out. Phosphor `signOut`.
  static const IconData signOut = IconData(
    0xe42a,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Call. Phosphor `phone`.
  static const IconData phone = IconData(
    0xe3b8,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Call a person from the emergency card. Phosphor `phoneCall`.
  static const IconData phoneCall = IconData(
    0xe3ba,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Call the ambulance. Phosphor `siren`.
  static const IconData siren = IconData(
    0xe9b8,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Read only. Phosphor `lockSimple`.
  static const IconData lock = IconData(
    0xe308,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// The app mode. Phosphor `identificationCard`.
  static const IconData idCard = IconData(
    0xe2c8,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Tab «اليوم». Phosphor `houseSimple`.
  static const IconData house = IconData(
    0xe2c6,
    fontFamily: _family,
    fontPackage: _package,
  );

  // The bottom bar: each tab's outline icon, and its filled one while the tab
  // is selected. The native bar on iOS shows the same drawings
  // (ios/Runner/Assets.xcassets/tab_*.imageset), because iOS draws its own
  // symbols filled in a tab bar whether selected or not.

  /// «اليوم». Phosphor `house`.
  static const IconData tabToday = IconData(
    0xe2c2,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// «اليوم», selected. Phosphor `house` fill.
  static const IconData tabTodayFill = IconData(
    0xe2c2,
    fontFamily: _fillFamily,
    fontPackage: _package,
  );

  /// «الخطة». Phosphor `firstAidKit`.
  static const IconData tabPlan = IconData(
    0xe570,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// «الخطة», selected. Phosphor `firstAidKit` fill.
  static const IconData tabPlanFill = IconData(
    0xe570,
    fontFamily: _fillFamily,
    fontPackage: _package,
  );

  /// «السجل». Phosphor `notebook`.
  static const IconData tabRecord = IconData(
    0xe34e,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// «السجل», selected. Phosphor `notebook` fill.
  static const IconData tabRecordFill = IconData(
    0xe34e,
    fontFamily: _fillFamily,
    fontPackage: _package,
  );

  /// «الدائرة», selected. Phosphor `users` fill; [users] is its outline.
  static const IconData tabCircleFill = IconData(
    0xe4d6,
    fontFamily: _fillFamily,
    fontPackage: _package,
  );
}
