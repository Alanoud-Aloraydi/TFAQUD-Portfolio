import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';

/// Tokens of the normal appearance.
const AppTokens appTokensLight = AppTokens(
  textSecondary: AppSemanticColors.textSupporting,
  focus: AppSemanticColors.textSupporting,
  borderControl: AppSemanticColors.borderControlBase,
  success: AppSemanticColors.statusSuccess,
  successText: AppSemanticColors.statusSuccess,
  warning: AppSemanticColors.statusWarning,
  warningText: AppSemanticColors.statusWarning,
  error: AppSemanticColors.statusError,
  errorText: AppSemanticColors.statusError,
  infoText: AppSemanticColors.statusInfo,
  glassBorder: AppSemanticColors.surfaceContent,
);

/// Tokens with iOS Increase Contrast on.
const AppTokens appTokensContrast = AppTokens(
  textSecondary: AppSemanticColors.textPrimary,
  focus: AppSemanticColors.textSupporting,
  borderControl: AppSemanticColors.textSupporting,
  success: AppSemanticColors.statusSuccess,
  successText: AppSemanticColors.textPrimary,
  warning: AppSemanticColors.statusWarning,
  warningText: AppSemanticColors.textPrimary,
  error: AppSemanticColors.statusError,
  errorText: AppSemanticColors.textPrimary,
  infoText: AppSemanticColors.textPrimary,
  glassBorder: AppSemanticColors.textSupporting,
);
