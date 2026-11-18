import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/components/filled_button_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared button themes for the current application appearance.
abstract class AppButtonThemes {
  AppButtonThemes._();

  /// Primary: leaf fill, ink label, capsule, 48 high.
  static FilledButtonThemeData filledButton(AppTokens tokens) =>
      buildFilledButtonTheme(tokens);

  /// Secondary: surface fill, a 1px control border, ink label, capsule.
  static OutlinedButtonThemeData outlinedButton(AppTokens tokens) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        shape: const StadiumBorder(),
        backgroundColor: AppSemanticColors.surfaceContent,
        foregroundColor: AppSemanticColors.textPrimary,
        disabledForegroundColor: tokens.textSecondary,
        textStyle: const TextStyle(
          fontFamily: AppTextTheme.fontFamily,
          fontSize: 15,
          height: 24 / 15,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: tokens.borderControl),
      ),
    );
  }

  /// Plain: no fill, ink label, keeps the 44 touch height.
  static TextButtonThemeData textButton(AppTokens tokens) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        shape: const StadiumBorder(),
        foregroundColor: AppSemanticColors.textPrimary,
        disabledForegroundColor: tokens.textSecondary,
        textStyle: const TextStyle(
          fontFamily: AppTextTheme.fontFamily,
          fontSize: 15,
          height: 24 / 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static final IconButtonThemeData iconButton = IconButtonThemeData(
    style: ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(AppSizes.touch, AppSizes.touch),
      ),
      foregroundColor: WidgetStatePropertyAll<Color>(
        AppSemanticColors.textPrimary,
      ),
    ),
  );

  /// Any other floating action button follows the primary action.
  static final FloatingActionButtonThemeData fab =
      FloatingActionButtonThemeData(
        backgroundColor: AppSemanticColors.actionPrimary,
        foregroundColor: AppSemanticColors.onActionPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      );
}
