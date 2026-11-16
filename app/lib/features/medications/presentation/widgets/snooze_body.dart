import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/snooze_header.dart';
import 'package:app/features/medications/presentation/widgets/snooze_limit_note.dart';
import 'package:app/features/medications/presentation/widgets/snooze_ruler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
