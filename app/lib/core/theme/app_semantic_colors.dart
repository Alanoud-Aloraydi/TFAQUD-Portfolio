import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Stable brand roles; adaptive foregrounds and borders live in AppTokens.
abstract class AppSemanticColors {
  AppSemanticColors._();

  /// High-contrast text and icon color.
  static const Color textPrimary = AppColors.ink;
  static const Color textSupporting = AppColors.slate;

  /// Foreground surface used by content containers.
  static const Color surfaceContent = AppColors.surface;

  /// Default background behind app screens.
  static const Color background = AppColors.canvas;
  static const Color borderSubtle = AppColors.line;
  static const Color borderControlBase = AppColors.stone;

  /// Primary action fill across the app.
  static const Color actionPrimary = AppColors.leaf;
  static const Color actionHover = AppColors.leafHover;
  static const Color actionPressed = AppColors.leafPressed;
  static const Color onActionPrimary = AppColors.ink;
  static const Color disabledSurface = AppColors.line;
  static const Color selectedSurface = AppColors.leafTint;

  /// The folding groups of «السجل», a shade off the page behind them.
  static const Color surfaceFold = AppColors.leafMist;

  /// What a chosen box is filled with where the fill alone must say so,
  /// the tint being too near white to be seen on its own.
  static const Color selectedSurfaceStrong = AppColors.leafTintDeep;
  static const Color focusOnAction = AppColors.ink;
  static const Color accentLeaf = AppColors.leaf;

  /// Accent for prayer periods and attention notices.
  static const Color accentWarm = AppColors.honey;

  /// The action that must stand out on a tinted surface: the pale
  /// [actionPrimary] reaches 1.8:1 on the simplified mode's honey card;
  /// this deep violet, 11.3:1 there and 12.1:1 on white, takes white words.
  static const Color actionStrong = AppColors.inkViolet;

  /// The fixed mark over a ruler picker's chosen number: the brand's green
  /// deep enough to stand out on white (above 3:1), unlike the pale leaf.
  static const Color pickerMark = AppColors.success;

  /// Lines inside a slate group, the edge of white avatars and small
  /// buttons on it, and the neutral badge «مدير».
  static const Color borderPlan = AppColors.slatePale;

  static const Color surfaceAttention = AppColors.honeyLight;
  static const Color surfaceAttentionGroup = AppColors.cream;
  static const Color borderAttentionGroup = AppColors.creamEdge;
  static const Color borderAttention = AppColors.honeyBorder;
  static const Color doseTrack = AppColors.slatePale;
  static const Color doseDueMarker = AppColors.honeyDeep;
  static const Color statusSuccess = AppColors.success;
  static const Color statusInfo = AppColors.info;

  /// The readings on a month chart: the violet's own ink, not the text's.
  static const Color chartInk = AppColors.inkViolet;

  /// The fill of a status badge. «سارية» had the selected row's violet and
  /// «قادم» had the neutral grey, so neither read as a status of its own.
  static const Color surfaceSuccess = AppColors.successLight;
  static const Color surfaceInfo = AppColors.infoLight;
  static const Color statusWarning = AppColors.warning;
  static const Color statusError = AppColors.error;

  /// The allergy box of the emergency card: a light red with a red edge.
  static const Color surfaceDanger = AppColors.errorLight;
  static const Color borderDanger = AppColors.errorBorder;

  /// The track of an opaque segmented switch (the card's «عربي / English»).
  static const Color segmentTrack = AppColors.slateMist;

  /// Small supporting text on ink, such as «فصيلة الدم» in the dark box.
  static const Color onInkSupporting = AppColors.slateSoft;

  static const Color navigationSelected = AppColors.ink;
  static const Color overlayScrim = Color(0x66202734);

  /// The light dim behind a glass sheet: ink at 18%, lighter than an
  /// alert's, so the page stays readable.
  static const Color sheetScrim = Color(0x2E202734);
  static const Color transparent = Colors.transparent;
}
