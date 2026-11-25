import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/plan_fact_group.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_version.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/widgets/plan_days_block.dart';
import 'package:app/features/measurements/presentation/widgets/plan_reading_rows.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الجدولة» of the plan form: the reading times, the days, the start, and
/// how long a missed reading waits.
///
/// [onChanged] runs a change of the schedule and draws it again; [onEdit]
/// does that and also clears the error shown, as a change of a reading does.
class MeasurementPlanFormSchedule extends StatelessWidget {
  const MeasurementPlanFormSchedule({
    super.key,
    required this.schedule,
    required this.kind,
    required this.isNew,
    required this.missedAfterChecked,
    required this.errorKey,
    required this.onChanged,
    required this.onEdit,
    required this.onAdd,
  });

  final PlanScheduleDraft schedule;
  final MeasurementKind kind;
  final bool isNew;
  final bool missedAfterChecked;

  /// A refusal of the days or of two same times, said under its row.
  final String? errorKey;
  final void Function(VoidCallback change) onChanged;
  final void Function(VoidCallback change) onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => InsetGroup(
    header: context.tr('measurements.schedule'),
    children: [
      ...planReadingRows(
        readings: schedule.readings,
        kind: kind,
        errorKey: errorKey,
        onEdit: onEdit,
        onAdd: onAdd,
      ),
      PlanDaysBlock(days: schedule.days, errorKey: errorKey, onEdit: onEdit),
      PlanStartRow(
        start: schedule.start,
        isNew: isNew,
        onPicked: (DateTime value) => onChanged(() => schedule.start = value),
      ),
      MissedAfterField(
        key: ValueKey<String>('missed-after-${kind.name}'),
        label: context.tr('measurements.missed_after'),
        minutes: schedule.missedAfter,
        showError: missedAfterChecked,
        onChanged: (int? minutes) =>
            onChanged(() => schedule.missedAfter = minutes),
      ),
    ],
  );
}

/// «يسري التعديل من 9 نوفمبر 2026» (or Hijri, as chosen in «حسابي»): the
/// change of a plan that waits for its day.
class MeasurementPlanPendingNote extends StatelessWidget {
  const MeasurementPlanPendingNote({super.key, required this.pending});

  final MeasurementVersion pending;

  @override
  Widget build(BuildContext context) => PlanInfoBox(
    emphasis: true,
    child: Text(
      context.tr(
        'measurements.pending_change',
        args: <String>[calendarDate(context, pending.effectiveFromOn)],
      ),
    ),
  );
}
