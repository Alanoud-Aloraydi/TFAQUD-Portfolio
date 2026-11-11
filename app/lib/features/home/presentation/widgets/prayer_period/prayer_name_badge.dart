import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The prayer name, with the «الحالية» badge beside it (below it when the
/// text is large and the line is full).
class PrayerNameBadge extends StatelessWidget {
  const PrayerNameBadge({super.key, required this.name, required this.current});

  final String name;
  final bool current;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(name, style: Theme.of(context).textTheme.titleMedium),
      if (current)
        CompactStatusBadge(
          text: context.tr('today_dashboard.current_period'),
          background: AppSemanticColors.surfaceAttention,
          foreground: context.tokens.warningText,
        ),
    ],
  );
}
