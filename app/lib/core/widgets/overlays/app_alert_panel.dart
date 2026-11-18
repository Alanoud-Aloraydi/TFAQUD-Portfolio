import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

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
