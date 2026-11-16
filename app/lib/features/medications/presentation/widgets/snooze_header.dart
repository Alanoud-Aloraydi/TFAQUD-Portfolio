import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «بعد ساعة و30 دقيقة» over the time it means on the patient's clock.
class SnoozeHeader extends StatelessWidget {
  const SnoozeHeader({super.key, required this.minutes, required this.clock});

  final int minutes;
  final PatientClock clock;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String at = wallTimeText(clock.now().add(Duration(minutes: minutes)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          afterDuration(context, minutes),
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        Text(
          context.tr('reminders.snooze_at', args: <String>[at]),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
