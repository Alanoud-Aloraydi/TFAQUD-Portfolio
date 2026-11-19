import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_readings.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_scope.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_existing_notice.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_note.dart';
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
