import 'package:flutter/material.dart';

/// Heights and touch areas of the design system.
abstract class AppSizes {
  AppSizes._();

  /// Minimum touch area (Apple: 44 by 44 points).
  static const double touch = 44;

  /// Round glass buttons at the top: account and notifications.
  static const double glassButton = 44;

  /// Large capsule buttons such as «حفظ» (on the 4-point grid).
  static const double button = 48;

  /// The one answer a task asks for, a step taller than the choices
  /// beside it so the eye lands on it first.
  static const double buttonAnswer = 56;

  /// Single-line text fields: a 28 line and 12 above and below.
  static const double field = 52;

  /// The floating tab bar, and the add button beside it.
  static const double tabBar = 64;

  static const double icon = 24;
  static const double iconSmall = 20;

  /// The round initial of a person or circle in a row.
  static const double avatar = 40;

  /// Profile portraits in the top bar and member list.
  static const double avatarPortrait = 48;

  /// The round initial at the top of a page or a card that stands for one
  /// person: the account, a request, the emergency card.
  static const double avatarLarge = 56;

  /// The label column of a form row (design system `size-form-label`): the
  /// small grey label sits in it, and values and typed text start after it,
  /// so every row of a form lines up.
  static const double formLabel = 112;

  // Preserve the compact overrides used by existing pill and alert buttons.
  static const double compactButton = 48;

  /// The turning logo of a whole page that loads, as Claude Design sizes it.
  static const double loadingPage = 160;
  static const double spinnerStroke = 2.5;
  static const double pickerViewport = 216;
  static const double alertWidth = 320;
  static const double iconAction = 28;
  static const double iconEmpty = 36;
  static const double iconHero = 56;
  static const double divider = 1;
  static const double border = 1;
  static const double borderEmphasis = 2;
}

/// Concentric radius scale of the design system: an inner corner equals its
/// container's radius minus the padding between them (Apple).
/// A radius-l card with 16 padding holds radius-s shapes (28 − 16 = 12);
/// with 8 padding it holds a radius-m panel (28 − 8 = 20).
abstract class AppRadius {
  AppRadius._();

  /// Alerts: a 48 capsule button 12 inside the panel (24 + 12).
  static const double xl = 36;
  static const double l = 28; // standalone cards and grouped lists
  static const double m = 20; // nested in an l card with 8 padding
  static const double s = 12; // fields and tiles in an l card with 16 padding
  static const double xs = 4; // marks in an s shape with 8 padding

  /// Capsules: the radius is half the height (design system radius-capsule).
  static const double capsule = 999;

  /// Older names, kept so existing screens follow the new scale.
  static const double card = l;
  static const double field = s;
  static const double sheet = l;

  /// Rounded superellipse: the iOS corner shape (60% smoothing in Figma).
  static RoundedSuperellipseBorder shape(
    double radius, {
    BorderSide side = BorderSide.none,
  }) {
    return RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      side: side,
    );
  }
}
