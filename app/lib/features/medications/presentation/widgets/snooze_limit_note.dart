import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// How far the reminder can be put off: the app's own twelve hours, or the
/// shorter room left before the medicine's next dose.
class SnoozeLimitNote extends StatelessWidget {
  const SnoozeLimitNote({super.key, required this.maxMinutes});

  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final bool limited = maxMinutes < maxSnooze.inMinutes;
    return Text(
      context.tr(
        limited ? 'reminders.snooze_limit_next' : 'reminders.snooze_limit',
        args: <String>[durationText(context, maxMinutes)],
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.tokens.textSecondary),
    );
  }
}
