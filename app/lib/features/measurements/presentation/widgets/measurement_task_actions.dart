import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_painter.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// «تسجيل قراءة» and «تخطي» under a measurement row that can still be
/// answered, in the buttons every task shares (TaskButtonRole). Once the
/// next task of its kind is due ([superseded]) a reading would answer that
/// one, so only «تخطي» stays, under the reason ([sayWhy]: false where the
/// card says it already).
class MeasurementTaskActions extends StatelessWidget {
  const MeasurementTaskActions({
    super.key,
    required this.task,
    this.circleId,
    this.superseded = false,
    this.sayWhy = true,
  });

  final MeasurementOccurrence task;

  /// Null hides «ذكّرني لاحقًا»: a reminder belongs to a circle.
  final String? circleId;
  final bool superseded;
  final bool sayWhy;

  @override
  Widget build(BuildContext context) {
    final Widget buttons = TaskButtonGrid(
      answer: superseded
          ? null
          : TaskButton(
              role: TaskButtonRole.answer,
              icon: CupertinoIcons.checkmark,
              label: context.tr('measurements.record_reading'),
              onPressed: () =>
                  showMeasurementReadingSheet(context, occurrence: task),
            ),
      choices: <Widget>[
        if (!superseded && circleId != null)
          MeasurementSnoozeButton(task: task, circleId: circleId!),
        TaskButton(
          role: TaskButtonRole.skip,
          icon: CupertinoIcons.minus_circle,
          label: context.tr('measurements.skip'),
          onPressed: () => skipMeasurement(context, task),
        ),
      ],
    );
    if (!superseded || !sayWhy) return buttons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.tr('measurements.superseded'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        buttons,
      ],
    );
  }
}

/// «بعد 5 ساعات من الموعد»; without the reading's time, «تسجّلت بعد
/// الموعد».
String measurementLateLine(BuildContext context, MeasurementOccurrence task) {
  final MeasurementReading? record = task.record;
  if (record == null) {
    return context.tr('today_dashboard.status.recorded_late');
  }
  final DateTime scheduled = PatientClockScope.of(context)
      .momentOf(task.scheduledOn, task.time);
  final Duration late = (record.measuredAt ?? record.recordedAt)
      .toUtc()
      .difference(scheduled.toUtc());
  return context.tr(
    'today_dashboard.status.late_line',
    args: <String>[lateByText(context, late)],
  );
}

/// Whether [task] was due before yesterday on the patient's calendar.
bool isOlderMeasurementTask(BuildContext context, MeasurementOccurrence task) {
  final DateTime yesterday = DateUtils.dateOnly(
    PatientClockScope.of(context).today(),
  ).subtract(const Duration(days: 1));
  return DateUtils.dateOnly(task.scheduledOn).isBefore(yesterday);
}
