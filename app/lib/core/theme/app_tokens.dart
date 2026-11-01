import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

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
