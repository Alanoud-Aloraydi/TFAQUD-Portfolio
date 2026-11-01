import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Shared depth definitions for opaque content.
abstract class AppEffects {
  AppEffects._();

  static const Color interactionOverlay = Color(0x14202734);
  static const Color subtleEdge = Color(0x1F202734);
  static const Color alertShadow = Color(0x29202734);
  static const Color shimmerClear = Color(0x00FFFFFF);
  static const Color shimmerHighlight = Color(0xB3FFFFFF);
  static final Color loadingScrim = AppSemanticColors.background.withAlpha(225);
  static final Color emergencyCardBorder = AppSemanticColors.surfaceContent
      .withAlpha(51);
  static final Color orbitLine = AppSemanticColors.textPrimary.withValues(
    alpha: 0.12,
  );
  static final Color orbitOutline = AppSemanticColors.textPrimary.withValues(
    alpha: 0.18,
  );
  static const List<BoxShadow> alertPanelShadow = <BoxShadow>[
    BoxShadow(color: subtleEdge, blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> segmentShadow = <BoxShadow>[
    BoxShadow(color: interactionOverlay, blurRadius: 4, offset: Offset(0, 1)),
  ];
}
