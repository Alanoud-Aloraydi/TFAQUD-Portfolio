import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/snooze_ruler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «متى نذكّرك؟»: the person slides a ruler, 5 minutes a mark, up to
/// [limit] (12 hours, or less before the medicine's next dose), the same
/// ruler as «نذكّرك كل». Above it, how long («بعد ساعة و30 دقيقة») and the
/// time it means on the patient's [clock]. Returns the minutes chosen, or
/// null when the sheet is closed.
Future<int?> showSnoozeSheet(
  BuildContext context, {
  required Duration limit,
  required PatientClock clock,
}) => showGlassSheet<int>(
  context,
  title: context.tr('reminders.snooze_title'),
  builder: (_) => SnoozeBody(maxMinutes: limit.inMinutes, clock: clock),
);

/// What the snooze sheet holds: how long, the time it means, the ruler, and
/// the button that puts the reminder off.
class SnoozeBody extends StatefulWidget {
  const SnoozeBody({super.key, required this.maxMinutes, required this.clock});

  final int maxMinutes;
  final PatientClock clock;

  @override
  State<SnoozeBody> createState() => _SnoozeBodyState();
}

class _SnoozeBodyState extends State<SnoozeBody> {
  /// 15 minutes to start with, when there is room for them.
  late int _minutes = widget.maxMinutes < 15 ? widget.maxMinutes : 15;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SnoozeHeader(minutes: _minutes, clock: widget.clock),
        const SizedBox(height: AppSpacing.md),
        if (widget.maxMinutes > snoozeStepMinutes)
          SnoozeRuler(
            maxMinutes: widget.maxMinutes,
            minutes: _minutes,
            onChanged: (int value) => setState(() => _minutes = value),
          ),
        const SizedBox(height: AppSpacing.sm),
        SnoozeLimitNote(maxMinutes: widget.maxMinutes),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('reminders.snooze_confirm'),
          onPressed: () => Navigator.pop<int>(context, _minutes),
        ),
      ],
    );
  }
}

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
