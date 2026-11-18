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
