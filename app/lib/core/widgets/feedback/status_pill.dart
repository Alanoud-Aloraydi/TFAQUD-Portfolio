import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The shape of every status label: a small rounded pill. Pages use
/// `StatusBadge`, which picks the colours from the status's tone.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
    this.border,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  /// An outline, for a fill that matches what the pill sits on.
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        border: border == null ? null : Border.all(color: border!),
        borderRadius: BorderRadius.circular(AppRadius.capsule),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: AppSizes.iconSmall, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          // Flexible, so a long label wraps at large text instead of
          // overflowing.
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: AppTextTheme.semibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
