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
  static const Color focusOnAction = AppColors.ink;
  static const Color accentLeaf = AppColors.leaf;

  /// Accent for prayer periods and attention notices.
  static const Color accentWarm = AppColors.honey;

  /// The small rounded squares behind a settings row's icon, as in iOS
  /// Settings: one color per kind of care, the icon in [onSettingsTile].
  static const Color settingsTileDoses = AppColors.leaf;
  static const Color settingsTileMeasurements = AppColors.honey;
  static const Color settingsTileAppointments = AppColors.slateSoft;
  static const Color onSettingsTile = AppColors.inkViolet;

  /// The fixed mark over a ruler picker's chosen number: the brand's green
  /// deep enough to stand out on white (above 3:1), unlike the pale leaf.
  static const Color pickerMark = AppColors.success;

  /// Lines inside a slate group, the edge of white avatars and small
  /// buttons on it, and the neutral badge «مدير».
  static const Color borderPlan = AppColors.slatePale;
  static const Color surfaceAttention = AppColors.honeyLight;
  static const Color borderAttention = AppColors.honeyBorder;
  static const Color doseTrack = AppColors.slatePale;
  static const Color doseDueMarker = AppColors.honeyDeep;
  static const Color statusSuccess = AppColors.success;
  static const Color statusInfo = AppColors.info;

  /// The readings drawn on a month chart: the violet's own ink, so the
  /// line and the dots belong to the palette and not to the text.
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

  /// The welcome pages: the page behind the pictures, the soft glows on it
  /// (two per page: warm honey, light leaf, and a calm grey blue on the
  /// last), and the dots of the pages not on show.
  static const Color introCanvas = AppColors.canvas;
  static const Color introGlowWarm = AppColors.honeyBorder;
  static const Color introGlowLeaf = AppColors.leafTint;
  static const Color introGlowMist = AppColors.slatePale;
  static const Color introGlowCalm = AppColors.slateMist;
  static const Color introDotIdle = AppColors.slateSoft;
  static const Color navigationSelected = AppColors.ink;
  static const Color overlayScrim = Color(0x66202734);

  /// The light dim behind a glass sheet: ink at 18%, lighter than an
  /// alert's, so the page stays readable.
  static const Color sheetScrim = Color(0x2E202734);
  static const Color transparent = Colors.transparent;
}
