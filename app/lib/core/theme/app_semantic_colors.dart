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

  /// Lines inside a slate group, the edge of white avatars and small
  /// buttons on it, and the neutral badge «مدير».
  static const Color borderPlan = AppColors.slatePale;
  static const Color surfaceAttention = AppColors.honeyLight;
  static const Color borderAttention = AppColors.honeyBorder;
  static const Color doseTrack = AppColors.slatePale;
  static const Color doseDueMarker = AppColors.honeyDeep;
  static const Color statusSuccess = AppColors.success;
  static const Color statusWarning = AppColors.warning;
  static const Color statusError = AppColors.error;

  /// The allergy box of the emergency card: a light red with a red edge.
  static const Color surfaceDanger = AppColors.errorLight;
  static const Color borderDanger = AppColors.errorBorder;

  /// The track of an opaque segmented switch (the card's «عربي / English»).
  static const Color segmentTrack = AppColors.slateMist;

  /// Small supporting text on ink, such as «فصيلة الدم» in the dark box.
  static const Color onInkSupporting = AppColors.slateSoft;

  /// The backgrounds of the three welcome pages, behind the guide owl:
  /// warm honey, light leaf and a calm grey blue.
  static const Color introWarm = AppColors.honeyLight;
  static const Color introLeaf = AppColors.leafTint;
  static const Color introCalm = AppColors.slateMist;
  static const Color navigationSelected = AppColors.ink;
  static const Color overlayScrim = Color(0x66202734);

  /// The light dim behind a glass sheet: ink at 18%, lighter than an
  /// alert's, so the page stays readable.
  static const Color sheetScrim = Color(0x2E202734);
  static const Color transparent = Colors.transparent;
}
