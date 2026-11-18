import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

const TextStyle _buttonLarge = TextStyle(
  fontFamily: AppTextTheme.fontFamily,
  fontSize: 17,
  height: 28 / 17,
  fontWeight: FontWeight.w600,
);

/// Primary: leaf fill, ink label, capsule, 48 high.
FilledButtonThemeData buildFilledButtonTheme(AppTokens tokens) {
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
        if (states.contains(WidgetState.disabled)) {
          return AppSemanticColors.disabledSurface;
        }
        if (states.contains(WidgetState.pressed)) {
          return AppSemanticColors.actionPressed;
        }
        if (states.contains(WidgetState.hovered)) {
          return AppSemanticColors.actionHover;
        }
        return AppSemanticColors.actionPrimary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.textSecondary;
        }
        return AppSemanticColors.onActionPrimary;
      }),
      // The pressed shade already shows the state.
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      side: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        // Ink remains distinct against both the green fill and canvas.
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(
            color: AppSemanticColors.focusOnAction,
            width: 2,
          );
        }
        return BorderSide.none;
      }),
    ),
  );
}
