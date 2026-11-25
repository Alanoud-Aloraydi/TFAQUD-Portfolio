import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/widgets/feedback/remind_later_check.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/dose_snooze_limit_of.dart';
import 'package:app/features/medications/presentation/widgets/registered_dose_reminders.dart';
import 'package:app/features/medications/presentation/widgets/snooze_button.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:app/features/medications/presentation/widgets/snooze_task_button.dart';
import 'package:app/features/medications/presentation/widgets/waiting_snooze.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
