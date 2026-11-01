import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:flutter/material.dart';

/// Shared surface themes for the current application appearance.
abstract class AppSurfaceThemes {
  AppSurfaceThemes._();

  /// Opaque cards on canvas: surface, radius-l, a 1px line edge, no shadow.
  static final CardThemeData card = CardThemeData(
    color: AppSemanticColors.surfaceContent,
    elevation: 0,
    margin: EdgeInsets.zero,
    surfaceTintColor: Colors.transparent,
    shape: AppRadius.shape(AppRadius.l, side: AppSurfaces.edge),
  );

  static final DialogThemeData dialog = DialogThemeData(
    backgroundColor: AppSemanticColors.surfaceContent,
    surfaceTintColor: Colors.transparent,
    barrierColor: AppSemanticColors.overlayScrim,
    shape: AppRadius.shape(AppRadius.l),
  );

  static final BottomSheetThemeData bottomSheet = BottomSheetThemeData(
    backgroundColor: AppSemanticColors.surfaceContent,
    modalBackgroundColor: AppSemanticColors.surfaceContent,
    modalBarrierColor: AppSemanticColors.overlayScrim,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: AppSemanticColors.borderControlBase,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
    ),
  );

  static final DividerThemeData divider = DividerThemeData(
    color: AppSemanticColors.borderSubtle,
    thickness: 1,
    space: 1,
  );

  static ListTileThemeData listTile(AppTokens tokens) {
    return ListTileThemeData(
      iconColor: tokens.textSecondary,
      textColor: AppSemanticColors.textPrimary,
      minTileHeight: AppSizes.touch,
      shape: AppRadius.shape(AppRadius.s),
    );
  }
}
