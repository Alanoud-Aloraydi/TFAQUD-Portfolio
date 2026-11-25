import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/layout/plan_fact_group.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_version.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
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

/// «الأيام» of a plan: the weekdays its readings are taken on.
class PlanDaysBlock extends StatelessWidget {
  const PlanDaysBlock({
    super.key,
    required this.days,
    required this.errorKey,
    required this.onEdit,
  });

  final Set<int> days;

  /// The form's refusal; «days_required» is said under the days.
  final String? errorKey;

  /// Runs a change of [days], clears the error and draws the form again.
  final void Function(VoidCallback change) onEdit;

  @override
  Widget build(BuildContext context) => FieldWithError(
    error: errorKey == 'measurements.days_required'
        ? context.tr(errorKey!)
        : null,
    child: InsetBlock(
      semanticLabel: context.tr('measurements.days'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('measurements.days')),
          const SizedBox(height: AppSpacing.sm),
          WeekdaySelector(
            selected: days,
            onChanged: (Set<int> chosen) => onEdit(() {
              days
                ..clear()
                ..addAll(chosen);
            }),
          ),
        ],
      ),
    ),
  );
}

/// «يبدأ» (a new plan) or «يسري من» (an edit): the first day, chosen on the
/// patient's calendar, never before the patient's today.
class PlanStartRow extends StatelessWidget {
  const PlanStartRow({
    super.key,
    required this.start,
    required this.isNew,
    required this.onPicked,
  });

  final DateTime start;
  final bool isNew;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final String label = context.tr(
      isNew ? 'measurements.starts' : 'measurements.effective_start',
    );
    return InsetRow(
      label: label,
      value: calendarDate(context, start),
      onTap: () async {
        final earliest = PatientClockScope.of(context).today();
        final selected = await showTafaqodDateSheet(
          context,
          title: label,
          initialDate: start.isBefore(earliest) ? earliest : start,
          firstDate: earliest,
          lastDate: earliest.add(const Duration(days: 3650)),
        );
        if (selected != null && context.mounted) onPicked(selected);
      },
    );
  }
}
