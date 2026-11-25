import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/remind_later_check.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/registered_dose_reminders.dart';
import 'package:app/features/medications/presentation/widgets/snooze_ruler.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:app/features/medications/presentation/widgets/snooze_task_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
