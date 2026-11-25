import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/snooze_button_state.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The ruler of the snooze sheet: 5 minutes a mark, a long mark every half
/// hour, and the hours written under them.
class SnoozeRuler extends StatelessWidget {
  const SnoozeRuler({
    super.key,
    required this.maxMinutes,
    required this.minutes,
    required this.onChanged,
  });

  final int maxMinutes;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return RulerPicker(
      min: snoozeStepMinutes,
      max: maxMinutes,
      step: snoozeStepMinutes,
      value: minutes,
      onChanged: onChanged,
      semanticLabel: context.tr('reminders.snooze_title'),
      valueLabel: (int value) => afterDuration(context, value),
      isMajor: (int value) => value % 30 == 0,
      tickLabel: (int value) => value % 60 == 0
          ? context.tr(
              'reminders.snooze_hours_tick',
              args: <String>['${value ~/ 60}'],
            )
          : '',
    );
  }
}

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

/// «ذكّرني لاحقًا»: the dose's own reminder again, as late as the person
/// slides the ruler of [showSnoozeSheet] (5 minutes a mark, up to 12 hours,
/// and never past halfway to the medicine's next dose), with the same
/// words as its notification. Once put off, the button says when it comes
/// («بنذكّرك 2:36 م»), and opens the ruler again. Put off by someone else
/// in the circle, it says until when and who («مؤجّلة إلى 2:36 م، لين»).
class SnoozeButton extends StatefulWidget {
  const SnoozeButton({
    super.key,
    required this.occurrence,
    required this.circleId,
  });

  final DoseOccurrence occurrence;
  final String circleId;

  @override
  State<SnoozeButton> createState() => SnoozeButtonState();
}
