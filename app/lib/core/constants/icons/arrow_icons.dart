import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/widgets.dart';

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
