import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_details.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_status.dart';
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
