import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The simplified mode's own scale over the app's tokens: larger type
/// (nothing below 18), bigger touch targets and one big action height, for
/// a patient who reads and taps less easily. Colors are the app's semantic
/// colors; only their roles here are named.
abstract final class SimplifiedStyle {
  // Layout.
  static const double page = AppSpacing.space5;
  static const double gap = AppSpacing.lg;
  static const double pad = AppSpacing.space5;
  static const double radius = AppRadius.l;

  /// The smallest tap target of the mode.
  static const double touch = 56;

  /// The height of a main action («أخذته الآن»).
  static const double action = 72;

  /// A round answer of a full-screen reminder.
  static const double answer = 104;

  // Type sizes.
  static const double caption = 18;
  static const double body = 20;
  static const double title = 22;
  static const double headline = 24;
  static const double name = 30;
  static const double display = 32;
  static const double hero = 40;
  static const double time = 44;
  static const double number = 56;

  // Color roles.
  static const Color ink = AppSemanticColors.textPrimary;
  static const Color muted = AppSemanticColors.textSupporting;
  static const Color canvas = AppSemanticColors.background;
  static const Color surface = AppSemanticColors.surfaceContent;
  static const Color line = AppSemanticColors.borderSubtle;
  static const Color control = AppSemanticColors.borderControlBase;
  static const Color accent = AppSemanticColors.actionPrimary;
  static const Color accentTint = AppSemanticColors.selectedSurface;
  static const Color success = AppSemanticColors.statusSuccess;
  static const Color attention = AppSemanticColors.surfaceAttention;
  static const Color attentionEdge = AppSemanticColors.accentWarm;
  static const Color attentionInk = AppSemanticColors.statusWarning;
  static const Color danger = AppSemanticColors.statusError;
  static const Color chip = AppSemanticColors.segmentTrack;
  static const Color disabled = AppSemanticColors.disabledSurface;
  static const Color onDarkMuted = AppSemanticColors.onInkSupporting;
  static const Color clear = AppSemanticColors.transparent;

  /// The calm dark ground of a full-screen reminder, like a call.
  static const LinearGradient reminderGround = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppSemanticColors.textSupporting,
      AppSemanticColors.textPrimary,
    ],
  );

  /// The light green ground of «تم، شكرًا».
  static const LinearGradient doneGround = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppSemanticColors.selectedSurface,
      AppSemanticColors.actionPrimary,
    ],
  );

  static TextStyle head(
    double size, {
    Color color = ink,
    double height = 1.25,
  }) => TextStyle(
    fontSize: size,
    fontWeight: AppTextTheme.bold,
    color: color,
    height: height,
  );

  static TextStyle label(double size, {Color color = ink}) => TextStyle(
    fontSize: size,
    fontWeight: AppTextTheme.semibold,
    color: color,
    height: 1.3,
  );

  static TextStyle text(
    double size, {
    Color color = muted,
    FontWeight weight = AppTextTheme.regular,
  }) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.5);
}
