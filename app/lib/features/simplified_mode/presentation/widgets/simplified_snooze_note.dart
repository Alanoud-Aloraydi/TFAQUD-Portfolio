import 'package:app/core/l10n/duration_text.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// How far the reminder can be put off, in the detailed sheet's own
/// words: the app's twelve hours, the shorter room before the medicine's
/// next dose, or none at all.
class SimplifiedSnoozeNote extends StatelessWidget {
  const SimplifiedSnoozeNote({super.key, required this.maxMinutes});

  final int maxMinutes;

  @override
  Widget build(BuildContext context) => Text(
    maxMinutes <= 0
        ? context.tr('reminders.snooze_none')
        : context.tr(
            maxMinutes < maxSnooze.inMinutes
                ? 'reminders.snooze_limit_next'
                : 'reminders.snooze_limit',
            args: <String>[durationText(context, maxMinutes)],
          ),
    textAlign: TextAlign.center,
    style: SimplifiedStyle.text(
      SimplifiedStyle.body,
      color: SimplifiedStyle.onDarkMuted,
    ),
  );
}
