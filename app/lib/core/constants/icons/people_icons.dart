import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/widgets.dart';

/// The circle's people: members, roles, invitations, calls and the app mode.
abstract final class PeopleIcons {
  /// «مدير». Phosphor `crown`.
  static const IconData crown = IconData(
    0xe614,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// A person, «صاحب الملف». Phosphor `user`.
  static const IconData user = IconData(
    0xe4c2,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// The circle. Phosphor `users`.
  static const IconData users = IconData(
    0xe4d6,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Add a member. Phosphor `userPlus`.
  static const IconData userPlus = IconData(
    0xe4d0,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// A pending invitation. Phosphor `hourglassMedium`.
  static const IconData hourglass = IconData(
    0xe2b8,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Send an invitation. Phosphor `paperPlaneTilt`.
  static const IconData paperPlane = IconData(
    0xe398,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Call. Phosphor `phone`.
  static const IconData phone = IconData(
    0xe3b8,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Call a person from the emergency card. Phosphor `phoneCall`.
  static const IconData phoneCall = IconData(
    0xe3ba,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// The app mode. Phosphor `identificationCard`.
  static const IconData idCard = IconData(
    0xe2c8,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );
}
