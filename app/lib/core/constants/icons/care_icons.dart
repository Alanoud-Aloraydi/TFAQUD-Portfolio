import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/widgets.dart';

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
