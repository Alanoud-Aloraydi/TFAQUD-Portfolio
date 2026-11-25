import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
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

/// Shared selection themes for the current application appearance.
abstract class AppSelectionThemes {
  AppSelectionThemes._();

  static ChipThemeData chip(AppTokens tokens) {
    return ChipThemeData(
      backgroundColor: AppSemanticColors.surfaceContent,
      selectedColor: AppSemanticColors.selectedSurface,
      checkmarkColor: AppSemanticColors.textPrimary,
      disabledColor: AppSemanticColors.borderSubtle,
      // A chosen chip's line is a deeper shade of its own violet fill,
      // not a grey ruled around it. An unchosen chip is white, so it
      // keeps the control grey that makes it read as a thing to press.
      side: WidgetStateBorderSide.resolveWith(
        (Set<WidgetState> states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? AppSemanticColors.selectedSurface
              : tokens.borderControl,
        ),
      ),
      shape: const StadiumBorder(),
      showCheckmark: true,
      // The chip theme's label style replaces Material's default, so it must
      // name the app font itself; without it the options of «الأمراض
      // المزمنة» and «الحساسية» showed in the system font.
      labelStyle: const TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: AppSemanticColors.textPrimary,
        fontSize: 15,
        height: 24 / 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static CheckboxThemeData checkbox(AppTokens tokens) => CheckboxThemeData(
    checkColor: WidgetStatePropertyAll<Color>(AppSemanticColors.surfaceContent),
    side: BorderSide(color: tokens.borderControl, width: 1.5),
  );

  static final RadioThemeData radio = RadioThemeData(
    fillColor: WidgetStatePropertyAll<Color>(AppSemanticColors.textPrimary),
  );
}
