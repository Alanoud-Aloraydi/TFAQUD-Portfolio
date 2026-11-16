import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_snooze_button.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_snooze_limit_of.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/registered_dose_reminders.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:app/features/medications/presentation/widgets/snooze_task_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows how the measurement stands with its reminder, and puts it off.
class MeasurementSnoozeButtonState extends State<MeasurementSnoozeButton> {
  Future<void> _snooze() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final PatientClock clock = PatientClockScope.of(context);
    final Duration limit = measurementSnoozeLimitOf(context, widget.task);
    if (limit.inMinutes < snoozeStepMinutes) {
      AppToast.showText(messenger, context.tr('reminders.snooze_none'));
      return;
    }
    final int? minutes = await showSnoozeSheet(
      context,
      limit: limit,
      clock: clock,
    );
    if (!mounted) return;
    final DoseReminders? reminders = registeredDoseReminders();
    if (minutes == null || reminders == null) return;
    await reminders.snoozeMeasurement(
      widget.circleId,
      widget.task,
      Duration(minutes: minutes),
    );
    if (!mounted) return;
    AppToast.showText(
      messenger,
      context.tr(
        'reminders.snoozed',
        args: <String>[afterDuration(context, minutes)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DoseReminders? reminders = registeredDoseReminders();
    final SharedSnooze? shared = widget.task.snooze;
    if (reminders == null) {
      return SnoozeTaskButton(at: null, shared: shared, onPressed: _snooze);
    }
    final String key = measurementSnoozeKey(widget.circleId, widget.task);
    return ValueListenableBuilder<Map<String, TaskSnooze>>(
      valueListenable: reminders.snoozes,
      builder: (BuildContext context, Map<String, TaskSnooze> snoozed, _) =>
          SnoozeTaskButton(
            at: snoozed[key]?.at,
            shared: shared,
            onPressed: _snooze,
          ),
    );
  }
}
