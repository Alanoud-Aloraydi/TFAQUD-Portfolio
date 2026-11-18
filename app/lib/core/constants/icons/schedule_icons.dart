import 'package:app/core/constants/icons/phosphor_font.dart';
import 'package:flutter/widgets.dart';

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

  /// A skipped dose. Phosphor `prohibit`.
  static const IconData prohibit = IconData(
    0xe3de,
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
