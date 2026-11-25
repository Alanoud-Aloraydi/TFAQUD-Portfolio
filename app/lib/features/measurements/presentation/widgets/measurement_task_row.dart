import 'package:app/app/services/reminders/shared_snooze.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_snooze.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One measurement task of «اليوم»: a [CareItemRow] with its condition,
/// status and the reading that answered it, and «تسجيل قراءة»/«تخطي» while
/// it can be answered ([now] is the patient's wall time); only «تخطي» once
/// the next task of its kind is due. The row itself is not tappable:
/// editing lives in «الخطة».
class MeasurementTaskRow extends StatelessWidget {
  const MeasurementTaskRow({
    super.key,
    required this.task,
    required this.now,
    required this.circleId,
    this.readOnly = false,
  });

  final MeasurementOccurrence task;
  final DateTime now;
  final String circleId;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final MeasurementTaskStatus status = MeasurementTaskStatus.of(
      context,
      task,
    );
    return CareItemRow(
      time: clockText(task.time),
      // The kind of reading first, then the clock.
      spokenLabel: <String>[
        measurementKindTitle(context, task.kind),
        clockText(task.time),
        if (status.lateBy case final String lateBy) lateBy,
        status.label,
      ].join('، '),
      tone: status.row,
      leading: const TodayTaskKindIcon(
        icon: CareVisuals.measurementIcon,
        background: CareVisuals.measurementTile,
      ),
      title: measurementKindTitle(context, task.kind),
      details: <Widget>[
        if (status.lateBy case final String lateBy)
          Text(lateBy, style: Theme.of(context).textTheme.bodySmall),
        ...measurementTaskDetails(context, task, circleId),
      ],
      status: StatusBadge(text: status.label, tone: status.badge),
      actions: canRecordMeasurement(task, now, readOnly: readOnly)
          ? MeasurementTaskActions(
              task: task,
              circleId: circleId,
              superseded: task.supersededAt(now),
            )
          : null,
    );
  }
}

/// Whether [task] can still be answered at [now] (the patient's wall time):
/// not once it is resolved or [readOnly], and only until the next task of
/// its kind is due.
bool canRecordMeasurement(
  MeasurementOccurrence task,
  DateTime now, {
  required bool readOnly,
}) {
  final bool resolved =
      task.status != MeasurementStatus.upcoming &&
      task.status != MeasurementStatus.due &&
      task.status != MeasurementStatus.missed;
  return !readOnly &&
      canRecordOccurrence(
        resolved: resolved,
        scheduledAt: wallClockAt(task.scheduledOn, task.time),
        now: now,
      );
}

/// The lines under a measurement row's title: its condition, a snooze, and
/// the reading that answered it.
List<Widget> measurementTaskDetails(
  BuildContext context,
  MeasurementOccurrence task,
  String circleId,
) {
  final MeasurementReading? record = task.record;
  final clock = PatientClockScope.of(context);
  final String? putOff = measurementSnoozeText(context, task, clock);
  return <Widget>[
    if (task.measurementState != null)
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: StatusBadge(
          text: context.tr('measurements.condition.${task.measurementState}'),
          tone: StatusTone.neutral,
        ),
      ),
    if (putOff != null)
      MeasurementTaskSnooze(task: task, text: putOff, circleId: circleId),
    if (record != null)
      ...measurementTaskRecordLines(context, record, clock, circleId),
  ];
}

/// «ذكّرني لاحقًا» put off by someone in the circle, while it waits.
String? measurementSnoozeText(
  BuildContext context,
  MeasurementOccurrence task,
  PatientClock clock,
) {
  final SharedSnooze? snooze = task.snooze;
  if (snooze == null || task.record != null) return null;
  final DateTime until = clock.wallTime(snooze.remindAt);
  if (!until.isAfter(clock.now())) return null;
  final String time = wallTimeText(until);
  return snooze.byName == null
      ? context.tr('measurements.snoozed_shared', args: <String>[time])
      : context.tr(
          'measurements.snoozed_by',
          args: <String>[time, snooze.byName!],
        );
}

/// The lines of the reading that answered a measurement task: its value,
/// when it was recorded, who recorded it, and why it was skipped.
List<Widget> measurementTaskRecordLines(
  BuildContext context,
  MeasurementReading record,
  PatientClock clock,
  String circleId,
) {
  final TextStyle? small = Theme.of(context).textTheme.bodySmall;
  return <Widget>[
    if (record.outcome == 'read')
      Text(record.valueText, style: Theme.of(context).textTheme.titleSmall),
    Text(
      context.tr(
        'measurements.recorded_at',
        args: <String>[wallTimeText(clock.wallTime(record.recordedAt))],
      ),
      style: small,
    ),
    if (record.recordedByName case final String name)
      RecorderLine(
        name: name,
        photoPath: personPhotoPath(circleId, record.recordedByAccountId),
        avatarCode: record.recordedByAvatarCode,
      ),
    if (record.outcome == 'skipped' && record.skipReasonCode != null)
      Text(
        context.tr(
          'measurements.skip_reason_line',
          args: <String>[measurementSkipReasonText(context, record)],
        ),
        style: small,
      ),
  ];
}
