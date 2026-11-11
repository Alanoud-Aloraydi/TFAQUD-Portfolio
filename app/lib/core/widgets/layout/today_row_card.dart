import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:flutter/material.dart';

enum TodayRowTone { normal, attention, danger }

/// Shared card shell for one row of Today's schedule (a dose, a measurement
/// task, an appointment): same background, radius and padding. Attention is
/// warm yellow while the task can still be handled; red is reserved for an
/// older task that is truly missed.
class TodayRowCard extends StatelessWidget {
  const TodayRowCard({
    super.key,
    required this.child,
    this.tone = TodayRowTone.normal,
  });

  final Widget child;
  final TodayRowTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: switch (tone) {
          TodayRowTone.normal => AppSemanticColors.surfaceContent,
          TodayRowTone.attention => AppSemanticColors.surfaceAttention,
          TodayRowTone.danger => Theme.of(context).colorScheme.errorContainer,
        },
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: switch (tone) {
          TodayRowTone.normal => null,
          TodayRowTone.attention => Border.all(
            color: AppSemanticColors.borderAttention,
          ),
          TodayRowTone.danger => Border.all(color: context.tokens.error),
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

/// The care kind at the start of each row: the same size and kind colour for
/// medication, measurement and appointment rows.
class TodayTaskKindIcon extends StatelessWidget {
  const TodayTaskKindIcon({
    super.key,
    required this.icon,
    required this.background,
  });

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(
        icon,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.onSettingsTile,
      ),
    ),
  );
}

enum TodayStatusTone { neutral, attention, success, danger }

/// One status colour language shared by every kind of task in «اليوم».
class TodayTaskStatusBadge extends StatelessWidget {
  const TodayTaskStatusBadge({
    super.key,
    required this.text,
    required this.tone,
  });

  final String text;
  final TodayStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      TodayStatusTone.neutral => (
        AppSemanticColors.surfaceContent,
        context.tokens.textSecondary,
      ),
      TodayStatusTone.attention => (
        AppSemanticColors.surfaceAttention,
        context.tokens.warningText,
      ),
      TodayStatusTone.success => (
        AppSemanticColors.selectedSurface,
        context.tokens.successText,
      ),
      TodayStatusTone.danger => (
        Theme.of(context).colorScheme.errorContainer,
        context.tokens.errorText,
      ),
    };
    return CompactStatusBadge(
      text: text,
      background: background,
      foreground: foreground,
    );
  }
}
