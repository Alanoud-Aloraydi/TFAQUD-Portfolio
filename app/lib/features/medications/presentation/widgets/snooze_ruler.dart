import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/remind_later_check.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/registered_dose_reminders.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:app/features/medications/presentation/widgets/snooze_task_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// Shows how the dose stands with its reminder, and puts it off.
class SnoozeButtonState extends State<SnoozeButton> {
  Future<void> _snooze() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!await mayRemindLater(context) || !mounted) return;
    final Duration limit = doseSnoozeLimitOf(context, widget.occurrence);
    if (limit.inMinutes < snoozeStepMinutes) {
      AppToast.showText(messenger, context.tr('reminders.snooze_none'));
      return;
    }
    final int? minutes = await showSnoozeSheet(
      context,
      limit: limit,
      clock: PatientClockScope.of(context),
    );
    if (!mounted) return;
    final DoseReminders? reminders = registeredDoseReminders();
    if (minutes == null || reminders == null) return;
    final bool done = await reminders.snoozeDose(
      widget.circleId,
      widget.occurrence,
      Duration(minutes: minutes),
    );
    if (!mounted) return;
    sayRemindLater(
      messenger,
      context,
      done: done,
      snoozed: context.tr(
        'reminders.snoozed',
        args: <String>[afterDuration(context, minutes)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SharedSnooze? waiting = waitingSnooze(context, widget.occurrence);
    final DoseReminders? reminders = registeredDoseReminders();
    if (reminders == null) {
      return SnoozeTaskButton(at: null, shared: waiting, onPressed: _snooze);
    }
    final String key = doseSnoozeKey(widget.circleId, widget.occurrence);
    return ValueListenableBuilder<Map<String, TaskSnooze>>(
      valueListenable: reminders.snoozes,
      builder: (BuildContext context, Map<String, TaskSnooze> snoozed, _) =>
          SnoozeTaskButton(
            at: snoozed[key]?.at,
            shared: waiting,
            onPressed: _snooze,
          ),
    );
  }
}

/// The circle's own snooze on [occurrence] while it still waits (the
/// server's), on the patient's wall clock, as the rest of the card. Null
/// once the time it was put off to has passed.
SharedSnooze? waitingSnooze(BuildContext context, DoseOccurrence occurrence) {
  final PatientClock clock = PatientClockScope.of(context);
  final SharedSnooze? shared = occurrence.snooze;
  if (shared == null) return null;
  return clock.wallTime(shared.remindAt).isAfter(clock.now()) ? shared : null;
}

/// How long the dose may still be put off: 12 hours, and never past
/// halfway to the next dose of the same medicine.
Duration doseSnoozeLimitOf(BuildContext context, DoseOccurrence occurrence) {
  final PatientClock clock = PatientClockScope.of(context);
  return doseSnoozeLimit(
    occurrence,
    context.read<MedicationOccurrencesCubit>().state.occurrences,
    clock,
    DateTime.now().toUtc(),
  );
}
