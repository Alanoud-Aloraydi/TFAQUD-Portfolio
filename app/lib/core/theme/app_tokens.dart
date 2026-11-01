import 'package:app/core/theme/app_semantic_colors.dart';
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
    textSecondary: AppSemanticColors.textSupporting,
    focus: AppSemanticColors.textSupporting,
    borderControl: AppSemanticColors.borderControlBase,
    success: AppSemanticColors.statusSuccess,
    successText: AppSemanticColors.statusSuccess,
    warning: AppSemanticColors.statusWarning,
    warningText: AppSemanticColors.statusWarning,
    error: AppSemanticColors.statusError,
    errorText: AppSemanticColors.statusError,
    glassBorder: AppSemanticColors.surfaceContent,
  );

  static const AppTokens contrast = AppTokens(
    textSecondary: AppSemanticColors.textPrimary,
    focus: AppSemanticColors.textSupporting,
    borderControl: AppSemanticColors.textSupporting,
    success: AppSemanticColors.statusSuccess,
    successText: AppSemanticColors.textPrimary,
    warning: AppSemanticColors.statusWarning,
    warningText: AppSemanticColors.textPrimary,
    error: AppSemanticColors.statusError,
    errorText: AppSemanticColors.textPrimary,
    glassBorder: AppSemanticColors.textSupporting,
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
