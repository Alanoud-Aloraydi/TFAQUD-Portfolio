import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Blends two token sets, as ThemeExtension.lerp does.
AppTokens lerpAppTokens(AppTokens a, AppTokens b, double t) {
  return AppTokens(
    textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
    focus: Color.lerp(a.focus, b.focus, t)!,
    borderControl: Color.lerp(a.borderControl, b.borderControl, t)!,
    success: Color.lerp(a.success, b.success, t)!,
    successText: Color.lerp(a.successText, b.successText, t)!,
    warning: Color.lerp(a.warning, b.warning, t)!,
    warningText: Color.lerp(a.warningText, b.warningText, t)!,
    error: Color.lerp(a.error, b.error, t)!,
    errorText: Color.lerp(a.errorText, b.errorText, t)!,
    infoText: Color.lerp(a.infoText, b.infoText, t)!,
    glassBorder: Color.lerp(a.glassBorder, b.glassBorder, t)!,
  );
}
