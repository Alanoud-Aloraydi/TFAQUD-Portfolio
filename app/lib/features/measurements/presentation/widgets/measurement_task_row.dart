import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_details.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One measurement task of «اليوم»: a [CareItemRow] with its condition,
/// status and the reading that answered it, and «تسجيل قراءة»/«تخطي» while
/// it can be answered ([now] is the patient's wall time). The row itself is
/// not tappable: editing lives in «الخطة».
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
    final bool resolved =
        task.status != MeasurementStatus.upcoming &&
        task.status != MeasurementStatus.due &&
        task.status != MeasurementStatus.missed;
    final bool canRecord =
        !readOnly &&
        canRecordOccurrence(
          resolved: resolved,
          scheduledAt: wallClockAt(task.scheduledOn, task.time),
          now: now,
        );
    return CareItemRow(
      time: clockText(task.time),
      tone: status.row,
      leading: const TodayTaskKindIcon(
        icon: CareVisuals.measurementIcon,
        background: CareVisuals.measurementTile,
      ),
      title: measurementKindTitle(context, task.kind),
      details: measurementTaskDetails(context, task, circleId),
      status: TodayTaskStatusBadge(
        text: context.tr(status.labelKey),
        tone: status.badge,
      ),
      actions: canRecord ? MeasurementTaskActions(task: task) : null,
    );
  }
}
