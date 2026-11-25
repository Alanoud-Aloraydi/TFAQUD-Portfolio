import 'dart:math' as math;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The handle, the title and the optional message at the top of a glass
/// sheet.
class GlassSheetHeader extends StatelessWidget {
  const GlassSheetHeader({super.key, required this.title, this.message});

  final String title;
  final String? message;

  static const double _handleWidth = 36;
  static const double _handleHeight = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: _handleWidth,
              height: _handleHeight,
              decoration: ShapeDecoration(
                color: AppSemanticColors.textPrimary.withValues(alpha: 0.25),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(
                color: AppSemanticColors.textSupporting,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The room a glass sheet leaves above itself, under the status bar: the
/// height of the page's top bar, so a tall sheet starts below it.
const double glassSheetTopGap = 64;

/// The tallest a glass sheet grows on a screen of [media]: from the bottom
/// up to [glassSheetTopGap] under the status bar.
double glassSheetMaxHeight(MediaQueryData media) =>
    media.size.height - media.viewPadding.top - glassSheetTopGap;

/// How far the glass sheet floats above the screen's bottom edge, before its
/// own gap: over the keyboard while it is open, otherwise over the iPhone's
/// home indicator or Android's navigation bar. `useSafeArea` keeps a sheet
/// clear of the top and the sides only, and from Android 15 the app draws
/// under the navigation bar, whose buttons would cover the last row.
double glassSheetBottomInset(MediaQueryData media) =>
    math.max(media.viewInsets.bottom, media.viewPadding.bottom);
