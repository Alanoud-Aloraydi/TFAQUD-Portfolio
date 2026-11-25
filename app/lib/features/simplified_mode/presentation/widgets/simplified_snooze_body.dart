import 'package:app/core/localization/duration_text.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snooze_header.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snooze_steps.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «متى أذكّرك؟» as the detailed mode asks it, larger and straight on the
/// dark ground: how long, the clock time it means, the ruler with its «−»
/// and «+», and how far the reminder can go.
class SimplifiedSnoozeBody extends StatelessWidget {
  const SimplifiedSnoozeBody({
    super.key,
    required this.minutes,
    required this.maxMinutes,
    required this.clock,
    required this.onChanged,
  });

  /// What is chosen now, and the most that can be; zero when the next dose
  /// of the same medicine leaves no room.
  final int minutes;
  final int maxMinutes;

  /// «الساعة 6:27 مساءً», the time [minutes] means.
  final String clock;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    // The ruler takes the whole width, as in the detailed sheet.
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SimplifiedSnoozeHeader(
        minutes: maxMinutes > 0 ? minutes : null,
        clock: clock,
      ),
      // One mark alone is nothing to slide along.
      if (maxMinutes > snoozeStepMinutes) ...<Widget>[
        SimplifiedSnoozeRuler(
          maxMinutes: maxMinutes,
          minutes: minutes,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        SimplifiedSnoozeSteps(
          maxMinutes: maxMinutes,
          minutes: minutes,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
      SimplifiedSnoozeNote(maxMinutes: maxMinutes),
    ],
  );
}

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
      color: SimplifiedColors.onDarkMuted,
    ),
  );
}
