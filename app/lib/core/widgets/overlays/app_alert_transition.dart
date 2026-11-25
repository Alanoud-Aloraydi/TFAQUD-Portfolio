import 'dart:ui' show lerpDouble;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// How the alert comes and goes: it fades, and unless Reduce Motion is on it
/// also scales, from a little larger than its size with a small overshoot
/// when opening, and with a slight shrink while it fades when closing.
Widget appAlertTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final bool still = MediaQuery.disableAnimationsOf(context);
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final bool closing = animation.status == AnimationStatus.reverse;
      final double opacity = AppMotion.easeOut.transform(animation.value);
      if (still) return Opacity(opacity: opacity, child: child);
      // Opening: from 108% down to its size with a small overshoot.
      // Closing: a slight shrink while it fades.
      final double scale = closing
          ? lerpDouble(AppMotion.alertClosingScale, 1, animation.value)!
          : lerpDouble(
              AppMotion.alertOpeningScale,
              1,
              AppMotion.alertSpring.transform(animation.value),
            )!;
      return Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, child: child),
      );
    },
    child: child,
  );
}

/// The white rounded panel of an alert, with its shadow and padding.
class AppAlertPanel extends StatelessWidget {
  const AppAlertPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: AppRadius.shape(AppRadius.xl),
          color: AppSemanticColors.surfaceContent,
          shadows: AppEffects.alertPanelShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The title and the optional message of an alert, centered.
class AppAlertText extends StatelessWidget {
  const AppAlertText({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    // Text 16 from the panel's edge: 12 + 4.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          Text(title, textAlign: TextAlign.center, style: text.titleLarge),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(message!, textAlign: TextAlign.center, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}
