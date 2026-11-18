import 'package:app/core/theme/app_tokens_lerp.dart';
import 'package:app/core/theme/app_tokens_presets.dart';
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
    required this.infoText,
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
  final Color infoText;

  /// Edge of glass surfaces: a thin white edge, or slate with Increased
  /// Contrast, as Apple does.
  final Color glassBorder;

  static const AppTokens light = appTokensLight;

  static const AppTokens contrast = appTokensContrast;

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
    Color? infoText,
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
      infoText: infoText ?? this.infoText,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return lerpAppTokens(this, other, t);
  }
}

/// Adds app tokens context helpers to its target type.
extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
