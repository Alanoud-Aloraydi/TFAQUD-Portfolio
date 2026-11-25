import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/entities/measurement_conditions.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_ranges.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_schedule.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_kind_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The body of the plan form, from what the form holds.
mixin MeasurementPlanFormLayout
    on MeasurementPlanFormScope, MeasurementPlanFormReadings {
  Widget formBody(MeasurementPlan? plan, MeasurementPlan? existing) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MeasurementPlanKindSection(
          kind: kind,
          isNew: plan == null,
          onChanged: (value) => edit(() => kind = value),
        ),
        if (existing != null) ...[
          const SizedBox(height: AppSpacing.md),
          MeasurementPlanExistingNotice(
            circleId: widget.circleId,
            planId: existing.id,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        MeasurementPlanFormSchedule(
          schedule: schedule,
          kind: kind,
          isNew: plan == null,
          missedAfterChecked: missedAfterChecked,
          errorKey: errorKey,
          onChanged: setState,
          onEdit: edit,
          onAdd: addReading,
        ),
        const SizedBox(height: AppSpacing.xl),
        MeasurementPlanFormRanges(
          cubit: ranges,
          circleId: widget.circleId,
          kind: kind,
          readings: readings,
        ),
        if (plan != null)
          MeasurementPlanFormNote(
            text: context.tr(
              'measurements.edit_effective_hint',
              args: [calendarDate(context, schedule.start)],
            ),
          ),
      ],
    );
  }
}

/// A line of text under the plan form: the hint about when an edit starts,
/// or the reason the form was not saved.
class MeasurementPlanFormNote extends StatelessWidget {
  const MeasurementPlanFormNote({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Text(text, style: style),
  );
}

/// Adds a reading time to the schedule shown.
mixin MeasurementPlanFormReadings on MeasurementPlanFormScope {
  /// A new reading three hours after the last one (the same day), with the
  /// first «حالة القياس» of its kind not used yet.
  void addReading() {
    final TimeOfDay last = readings.last.time;
    final int next = last.hour * 60 + last.minute + 180;
    final int minutes = next > 23 * 60 ? 23 * 60 : next;
    final Set<String> used = {
      for (final item in readings) ?item.measurementState,
    };
    final String? meal = MeasurementConditions.planStates(kind)
        .where((String value) => !used.contains(value))
        .firstOrNull;
    edit(
      () => readings.add(
        PlanReadingDraft(
          TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
          meal,
        ),
      ),
    );
  }
}
