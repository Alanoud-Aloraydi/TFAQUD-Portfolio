import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Stable brand roles; adaptive foregrounds and borders live in AppTokens.
abstract class AppSemanticColors {
  AppSemanticColors._();

  static const Color textPrimary = AppColors.ink;
  static const Color textSupporting = AppColors.slate;
  static const Color surfaceContent = AppColors.surface;
  static const Color background = AppColors.canvas;
  static const Color borderSubtle = AppColors.line;
  static const Color borderControlBase = AppColors.stone;
  static const Color actionPrimary = AppColors.leaf;
  static const Color actionHover = AppColors.leafHover;
  static const Color actionPressed = AppColors.leafPressed;
  static const Color onActionPrimary = AppColors.ink;
  static const Color disabledSurface = AppColors.line;
  static const Color selectedSurface = AppColors.leafTint;
  static const Color focusOnAction = AppColors.ink;
  static const Color accentLeaf = AppColors.leaf;
  static const Color accentWarm = AppColors.honey;
  static const Color surfacePlan = AppColors.slateLight;
  static const Color surfaceAttention = AppColors.honeyLight;
  static const Color borderAttention = AppColors.honeyBorder;
  static const Color doseTrack = AppColors.slatePale;
  static const Color doseDueMarker = AppColors.honeyDeep;
  static const Color statusSuccess = AppColors.success;
  static const Color statusWarning = AppColors.warning;
  static const Color statusError = AppColors.error;
  static const Color navigationSelected = AppColors.ink;
  static const Color overlayScrim = Color(0x66202734);
  static const Color transparent = Colors.transparent;
}
