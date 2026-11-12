import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/ruler_picker.dart';
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
  builder: (_) => _SnoozeBody(maxMinutes: limit.inMinutes, clock: clock),
);

class _SnoozeBody extends StatefulWidget {
  const _SnoozeBody({required this.maxMinutes, required this.clock});

  final int maxMinutes;
  final PatientClock clock;

  @override
  State<_SnoozeBody> createState() => _SnoozeBodyState();
}

class _SnoozeBodyState extends State<_SnoozeBody> {
  /// 15 minutes to start with, when there is room for them.
  late int _minutes = widget.maxMinutes < 15 ? widget.maxMinutes : 15;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String at = wallTimeText(
      widget.clock.now().add(Duration(minutes: _minutes)),
    );
    final bool limited = widget.maxMinutes < maxSnooze.inMinutes;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          afterDuration(context, _minutes),
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        Text(
          context.tr('reminders.snooze_at', args: <String>[at]),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.maxMinutes > snoozeStepMinutes)
          RulerPicker(
            min: snoozeStepMinutes,
            max: widget.maxMinutes,
            step: snoozeStepMinutes,
            value: _minutes,
            onChanged: (int value) => setState(() => _minutes = value),
            semanticLabel: context.tr('reminders.snooze_title'),
            valueLabel: (int value) => afterDuration(context, value),
            // A long mark every half hour, the hours under them.
            isMajor: (int value) => value % 30 == 0,
            tickLabel: (int value) => value % 60 == 0
                ? context.tr(
                    'reminders.snooze_hours_tick',
                    args: <String>['${value ~/ 60}'],
                  )
                : '',
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(
            limited ? 'reminders.snooze_limit_next' : 'reminders.snooze_limit',
            args: <String>[durationText(context, widget.maxMinutes)],
          ),
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: context.tokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('reminders.snooze_confirm'),
          onPressed: () => Navigator.pop<int>(context, _minutes),
        ),
      ],
    );
  }
}
