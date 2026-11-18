import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// The simplified mode's color roles over the app's semantic colors; only
/// their roles here are named.
abstract final class SimplifiedColors {
  static const Color ink = AppSemanticColors.textPrimary;
  static const Color muted = AppSemanticColors.textSupporting;
  static const Color canvas = AppSemanticColors.background;
  static const Color surface = AppSemanticColors.surfaceContent;
  static const Color line = AppSemanticColors.borderSubtle;
  static const Color control = AppSemanticColors.borderControlBase;
  static const Color accent = AppSemanticColors.actionPrimary;

  /// The fill of the one action a screen asks for, deep enough to carry
  /// over the mode's tinted cards.
  static const Color accentStrong = AppSemanticColors.actionStrong;
  static const Color accentTint = AppSemanticColors.selectedSurface;
  static const Color success = AppSemanticColors.statusSuccess;
  static const Color attention = AppSemanticColors.surfaceAttentionGroup;
  static const Color attentionBorder = AppSemanticColors.borderAttentionGroup;
  static const Color attentionEdge = AppSemanticColors.accentWarm;
  static const Color attentionInk = AppSemanticColors.statusWarning;
  static const Color danger = AppSemanticColors.statusError;
  static const Color chip = AppSemanticColors.segmentTrack;
  static const Color disabled = AppSemanticColors.disabledSurface;
  static const Color onDarkMuted = AppSemanticColors.onInkSupporting;
  static const Color clear = AppSemanticColors.transparent;

  /// The calm dark ground of a full-screen reminder, like a call: one
  /// colour, never a gradient.
  static const Color reminderGround = AppSemanticColors.textPrimary;

  /// The ground of «تم، يعطيك العافية»: one colour, the light lavender.
  static const Color doneGround = AppSemanticColors.selectedSurface;

  /// Something done, in the detailed mode's «تم أخذها»: the pale green.
  static const Color successTint = AppSemanticColors.surfaceSuccess;
}
