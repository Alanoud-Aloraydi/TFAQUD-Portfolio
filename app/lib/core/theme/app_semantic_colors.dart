import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Fixed semantic roles of the existing appearance.
///
/// Adaptive roles remain in AppTokens. Keeping these fixed roles separate
/// preserves components that did not previously react to Increased Contrast.
abstract class AppSemanticColors {
  AppSemanticColors._();

  static const Color textPrimary = AppColors.ink;
  static const Color textSupporting = AppColors.slate;
  static const Color surfaceContent = AppColors.surface;
  static const Color background = AppColors.canvas;
  static const Color borderSubtle = AppColors.line;
  static const Color borderControlBase = AppColors.stone;
  static const Color actionPrimary = AppColors.ink;
  static const Color actionPressed = AppColors.slate;
  static const Color onActionPrimary = AppColors.surface;
  static const Color disabledSurface = AppColors.line;
  static const Color selectedSurface = AppColors.leafTint;
  static const Color focusOnAction = AppColors.honey;
  static const Color accentLeaf = AppColors.leaf;
  static const Color accentWarm = AppColors.honey;
  static const Color statusSuccess = AppColors.success;
  static const Color statusWarning = AppColors.warning;
  static const Color statusError = AppColors.error;
  static const Color navigationSelected = AppColors.success;
  static const Color overlayScrim = Color(0x66202734);
  static const Color transparent = Colors.transparent;
}
