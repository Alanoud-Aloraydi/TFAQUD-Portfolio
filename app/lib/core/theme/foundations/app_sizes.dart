/// Heights and touch areas of the design system.
abstract class AppSizes {
  AppSizes._();

  /// Minimum touch area (Apple: 44 by 44 points).
  static const double touch = 44;

  /// Round glass buttons at the top: account and notifications.
  static const double glassButton = 44;

  /// Large capsule buttons such as «حفظ» (on the 4-point grid).
  static const double button = 48;

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
  static const double loadingIndicator = 48;
  static const double spinnerStroke = 2.5;
  static const double phonePrefix = 84;
  static const double pickerViewport = 216;
  static const double alertWidth = 320;
  static const double iconAction = 28;
  static const double iconEmpty = 36;
  static const double iconHero = 56;
  static const double divider = 1;
  static const double border = 1;
  static const double borderEmphasis = 2;
  static const double borderStrong = 3;
}
