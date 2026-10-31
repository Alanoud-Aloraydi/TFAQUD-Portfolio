import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio of two opaque colors.
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Color? resolve(WidgetStateProperty<Color?>? property, Set<WidgetState> states) =>
    property?.resolve(states);

void main() {
  group('palette', () {
    test('text pairs of the design system stay readable', () {
      // Primary text on every approved ground, and on the leaf states.
      for (final Color ground in <Color>[
        AppColors.surface,
        AppColors.canvas,
        AppColors.leaf,
        AppColors.leafHover,
        AppColors.leafPressed,
        AppColors.leafTint,
        AppColors.line,
      ]) {
        expect(contrast(AppColors.ink, ground), greaterThanOrEqualTo(7));
      }
      // Supporting text reaches 7:1 on the light grounds too.
      for (final Color ground in <Color>[
        AppColors.surface,
        AppColors.canvas,
        AppColors.leafTint,
        AppColors.line,
      ]) {
        expect(contrast(AppColors.slate, ground), greaterThanOrEqualTo(7));
      }
      // Status words on the grounds they are approved on.
      for (final Color status in <Color>[
        AppColors.success,
        AppColors.warning,
        AppColors.error,
      ]) {
        expect(contrast(status, AppColors.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(status, AppColors.canvas), greaterThanOrEqualTo(4.5));
      }
      // Control borders and focus reach 3:1.
      expect(contrast(AppColors.stone, AppColors.surface), greaterThanOrEqualTo(3));
      expect(contrast(AppColors.stone, AppColors.canvas), greaterThanOrEqualTo(3));
      expect(contrast(AppColors.slate, AppColors.leaf), greaterThanOrEqualTo(3));
    });

    test('leaf is a fill, not a text color', () {
      expect(contrast(AppColors.leaf, AppColors.surface), lessThan(3));
    });
  });

  group('theme', () {
    test('the primary action is leaf with an ink label in every state', () {
      final ButtonStyle style = AppTheme.lightTheme.filledButtonTheme.style!;
      expect(resolve(style.backgroundColor, <WidgetState>{}), AppColors.leaf);
      expect(
        resolve(style.backgroundColor, <WidgetState>{WidgetState.hovered}),
        AppColors.leafHover,
      );
      expect(
        resolve(style.backgroundColor, <WidgetState>{WidgetState.pressed}),
        AppColors.leafPressed,
      );
      expect(
        resolve(style.backgroundColor, <WidgetState>{WidgetState.disabled}),
        AppColors.line,
      );
      expect(resolve(style.foregroundColor, <WidgetState>{}), AppColors.ink);
    });

    test('text, icons and selection marks are ink, never leaf', () {
      final ColorScheme scheme = AppTheme.lightTheme.colorScheme;
      expect(scheme.primary, AppColors.ink);
      expect(scheme.onSurface, AppColors.ink);
      expect(scheme.error, AppColors.error);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppColors.canvas);
    });

    test('Increased Contrast turns secondary text and status words ink', () {
      final AppTokens light = AppTheme.lightTheme.extension<AppTokens>()!;
      final AppTokens high = AppTheme.highContrastTheme.extension<AppTokens>()!;
      expect(light.textSecondary, AppColors.slate);
      expect(high.textSecondary, AppColors.ink);
      expect(light.borderControl, AppColors.stone);
      expect(high.borderControl, AppColors.slate);
      expect(high.successText, AppColors.ink);
      expect(high.warningText, AppColors.ink);
      expect(high.errorText, AppColors.ink);
      // Icons keep their status color.
      expect(high.success, AppColors.success);
      expect(high.error, AppColors.error);
    });

    test('radii are concentric: card minus padding', () {
      expect(AppRadius.l - AppSpacing.lg, AppRadius.s);
      expect(AppRadius.l - AppSpacing.sm, AppRadius.m);
      expect(AppRadius.s - AppSpacing.sm, AppRadius.xs);
    });

    test('the text theme uses IBM Plex Sans Arabic, 11 or larger', () {
      final TextTheme text = AppTheme.lightTheme.textTheme;
      expect(text.bodyLarge!.fontFamily, 'IBMPlexSansArabic');
      for (final TextStyle? style in <TextStyle?>[
        text.displaySmall,
        text.headlineLarge,
        text.titleLarge,
        text.bodyLarge,
        text.bodyMedium,
        text.bodySmall,
        text.labelSmall,
      ]) {
        expect(style!.fontSize, greaterThanOrEqualTo(11));
      }
    });
  });
}
