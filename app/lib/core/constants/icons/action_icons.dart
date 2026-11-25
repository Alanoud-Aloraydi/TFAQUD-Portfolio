import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

/// The actions on a button or a row: add, less, choose, close, delete, edit,
/// search and sign out.
abstract final class ActionIcons {
  /// Add. Phosphor `plus`.
  static const IconData plus = IconData(
    0xe3d4,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Add a row inside a form. Phosphor `plusCircle`.
  static const IconData plusCircle = IconData(
    0xe3d6,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Less (stepper). Phosphor `minus`.
  static const IconData minus = IconData(
    0xe32a,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Chosen. Phosphor `check`.
  static const IconData check = IconData(
    0xe182,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Taken. Phosphor `checkCircle`.
  static const IconData checkCircle = IconData(
    0xe184,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Close or cancel. Phosphor `x`.
  static const IconData x = IconData(
    0xe4f6,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Delete. Phosphor `trash`.
  static const IconData trash = IconData(
    0xe4a6,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// The edit pencil used throughout the app.
  static const IconData pencil = CupertinoIcons.pencil;

  /// Search. Phosphor `magnifyingGlass`.
  static const IconData search = IconData(
    0xe30c,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );

  /// Leave the circle, sign out. Phosphor `signOut`.
  static const IconData signOut = IconData(
    0xe42a,
    fontFamily: phosphorFamily,
    fontPackage: phosphorPackage,
  );
}

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
