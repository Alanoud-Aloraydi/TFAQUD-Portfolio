import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/measurements/presentation/models/plan_reading_draft.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_scope.dart';
import 'package:flutter/material.dart';

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
