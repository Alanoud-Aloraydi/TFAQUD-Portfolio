import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the minutes sheet holds: the length as said, what it
/// means, the ruler, and «تأكيد».
class MinutesSheetBody extends StatefulWidget {
  const MinutesSheetBody({
    super.key,
    required this.label,
    required this.minutes,
    required this.headline,
    required this.subline,
    required this.min,
    required this.max,
  });

  final String label;
  final int minutes;
  final String Function(int minutes) headline;
  final String Function(int minutes)? subline;
  final int min;
  final int max;

  @override
  State<MinutesSheetBody> createState() => _MinutesSheetBodyState();
}

class _MinutesSheetBodyState extends State<MinutesSheetBody> {
  late int _minutes = widget.minutes;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.headline(_minutes),
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        if (widget.subline case final String Function(int) subline)
          Text(
            subline(_minutes),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        RulerPicker(
          min: widget.min,
          max: widget.max,
          step: 5,
          value: _minutes,
          onChanged: (int value) => setState(() => _minutes = value),
          semanticLabel: widget.label,
          valueLabel: widget.headline,
          isMajor: (int value) => value % 30 == 0,
          tickLabel: (int value) => value % 60 == 0
              ? context.tr(
                  'reminders.snooze_hours_tick',
                  args: <String>['${value ~/ 60}'],
                )
              : '',
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('common.confirm'),
          onPressed: () => Navigator.pop<int>(context, _minutes),
        ),
      ],
    );
  }
}
