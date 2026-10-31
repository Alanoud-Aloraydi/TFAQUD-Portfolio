import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Spacing scale of the design system: a 4px base, mostly 8px steps.
/// The short names were here first; the design-system names say the same.
abstract class AppSpacing {
  AppSpacing._();

  static const double xs = 4; // space-1
  static const double sm = 8; // space-2
  static const double md = 12; // space-3
  static const double lg = 16; // space-4: screen margin, card padding
  static const double xl = 24; // space-6: between cards and form fields
  static const double xxl = 32; // space-8: between sections

  static const double space1 = xs;
  static const double space2 = sm;
  static const double space3 = md;
  static const double space4 = lg;

  /// Side padding of large buttons.
  static const double space5 = 20;
  static const double space6 = xl;
  static const double space8 = xxl;

  /// Above a screen's first section and around empty states.
  static const double space10 = 40;
}

/// Heights and touch areas of the design system.
abstract class AppSizes {
  AppSizes._();

  /// Minimum touch area (Apple: 44 by 44 points).
  static const double touch = 44;

  /// Round glass buttons at the top: account and notifications.
  static const double glassButton = 44;

  /// Large capsule buttons such as «حفظ».
  static const double button = 50;

  /// Single-line text fields.
  static const double field = 50;

  /// The floating tab bar, and the add button beside it.
  static const double tabBar = 64;

  static const double icon = 24;
  static const double iconSmall = 20;
}

/// Starting values of the custom glass (blur, white tint). They are values to
/// test on a device, not approved colors.
abstract class AppGlass {
  AppGlass._();

  static const double blurSigma = 14;
  static const double tintAlpha = 0.72;

  /// Soft shadow under floating glass: ink at low opacity.
  static const List<BoxShadow> shadow = <BoxShadow>[
    BoxShadow(color: Color(0x1F202734), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x14202734), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Soft shadow under opaque cards on canvas (surface is only 1.07:1 there).
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D202734), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D202734), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

/// Roles that change with the Increased Contrast setting, plus the colors that
/// have no slot in ColorScheme. Accessed through `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.textSecondary,
    required this.focus,
    required this.borderControl,
    required this.success,
    required this.successText,
    required this.warning,
    required this.warningText,
    required this.error,
    required this.errorText,
    required this.glassBorder,
  });

  /// Supporting text. slate, or ink with Increased Contrast.
  final Color textSecondary;

  /// Keyboard focus indicator on light surfaces.
  final Color focus;

  /// Necessary borders of inputs and controls. stone, or slate.
  final Color borderControl;

  /// Status icons keep their color in both themes.
  final Color success;
  final Color warning;
  final Color error;

  /// Status words. The status color, or ink with Increased Contrast.
  final Color successText;
  final Color warningText;
  final Color errorText;

  /// Edge of glass surfaces: a thin white edge, or slate with Increased
  /// Contrast, as Apple does.
  final Color glassBorder;

  static const AppTokens light = AppTokens(
    textSecondary: AppColors.slate,
    focus: AppColors.slate,
    borderControl: AppColors.stone,
    success: AppColors.success,
    successText: AppColors.success,
    warning: AppColors.warning,
    warningText: AppColors.warning,
    error: AppColors.error,
    errorText: AppColors.error,
    glassBorder: AppColors.surface,
  );

  static const AppTokens contrast = AppTokens(
    textSecondary: AppColors.ink,
    focus: AppColors.slate,
    borderControl: AppColors.slate,
    success: AppColors.success,
    successText: AppColors.ink,
    warning: AppColors.warning,
    warningText: AppColors.ink,
    error: AppColors.error,
    errorText: AppColors.ink,
    glassBorder: AppColors.slate,
  );

  @override
  AppTokens copyWith({
    Color? textSecondary,
    Color? focus,
    Color? borderControl,
    Color? success,
    Color? successText,
    Color? warning,
    Color? warningText,
    Color? error,
    Color? errorText,
    Color? glassBorder,
  }) {
    return AppTokens(
      textSecondary: textSecondary ?? this.textSecondary,
      focus: focus ?? this.focus,
      borderControl: borderControl ?? this.borderControl,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      error: error ?? this.error,
      errorText: errorText ?? this.errorText,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      borderControl: Color.lerp(borderControl, other.borderControl, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
