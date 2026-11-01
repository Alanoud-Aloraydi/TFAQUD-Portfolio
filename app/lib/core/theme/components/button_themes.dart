import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Shared button themes for the current application appearance.
abstract class AppButtonThemes {
  AppButtonThemes._();

  static const TextStyle _buttonLarge = TextStyle(
    fontFamily: AppTextTheme.fontFamily,
    fontSize: 17,
    height: 28 / 17,
    fontWeight: FontWeight.w600,
  );

  /// Primary: ink fill, white label, capsule, 48 high.
  static FilledButtonThemeData filledButton(AppTokens tokens) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(64, AppSizes.button),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: AppSpacing.space5),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        textStyle: const WidgetStatePropertyAll<TextStyle>(_buttonLarge),
        elevation: const WidgetStatePropertyAll<double>(0),
        backgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) return AppColors.line;
          // Pressed (and pointer hover) lightens to slate, the next navy of
          // the palette; the white label stays 10.19:1.
          if (states.contains(WidgetState.pressed)) return AppColors.slate;
          if (states.contains(WidgetState.hovered)) return AppColors.slate;
          return AppColors.ink;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled))
            return tokens.textSecondary;
          return AppColors.onInk;
        }),
        // The pressed shade already shows the state.
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        side: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          // Slate is only 1.47:1 on ink; the focus ring on ink is honey.
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.honey, width: 2);
          }
          return BorderSide.none;
        }),
      ),
    );
  }

  /// Secondary: surface fill, a 1px control border, ink label, capsule.
  static OutlinedButtonThemeData outlinedButton(AppTokens tokens) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
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
        foregroundColor: AppColors.ink,
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
      foregroundColor: WidgetStatePropertyAll<Color>(AppColors.ink),
    ),
  );

  /// Any other floating action button follows the primary action.
  static final FloatingActionButtonThemeData fab =
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      );
}
