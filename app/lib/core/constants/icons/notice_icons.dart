import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/widgets.dart';

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
