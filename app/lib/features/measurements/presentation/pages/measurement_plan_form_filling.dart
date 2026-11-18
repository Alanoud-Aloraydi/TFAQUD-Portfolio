import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/domain/measurement_version.dart';
import 'package:app/features/measurements/presentation/models/plan_reading_draft.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_scope.dart';
import 'package:flutter/material.dart';

/// Starts an edit from the plan being changed.
mixin MeasurementPlanFormFilling on MeasurementPlanFormScope {
  /// The plan of the page's `planId` among [plans], filled into the form
  /// the first time it is found; none for a new plan.
  MeasurementPlan? editedPlan(List<MeasurementPlan> plans) {
    if (widget.planId == null) return null;
    MeasurementPlan? plan;
    for (final item in plans) {
      // A stopped plan is not edited: it is gone from the plan tab.
      if (item.id == widget.planId && item.stoppedAt == null) plan = item;
    }
    if (plan != null) fill(plan);
    return plan;
  }

  void fill(MeasurementPlan plan) {
    if (initialized) return;
    initialized = true;
    // The latest version: a change waiting for later, when there is one,
    // so editing again starts from it.
    final version = plan.pendingVersion ?? plan.version;
    kind = plan.kind;
    readings
      ..clear()
      ..addAll(<PlanReadingDraft>[
        for (final MeasurementTime item in version.readingTimes)
          PlanReadingDraft(_parseTime(item.time), item.measurementState),
      ]);
    final earliest = PatientClockScope.of(context).today();
    start = version.effectiveFromOn.isAfter(earliest)
        ? version.effectiveFromOn
        : earliest;
    days
      ..clear()
      ..addAll(version.weekdays);
    missedAfter = version.missedAfterMinutes;
  }
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
