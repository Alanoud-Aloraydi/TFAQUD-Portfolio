import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The one explanation of what calendar sync does, shown once beneath
/// however many circles' toggles a page lists.
class CalendarSyncHint extends StatelessWidget {
  const CalendarSyncHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.sm,
        start: AppSpacing.inset,
        end: AppSpacing.inset,
      ),
      child: Text(
        context.tr('circle_overview.calendar_sync_hint'),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.tokens.textSecondary),
      ),
    );
  }
}
