import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/entities/measurement_version.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_saving.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_state.dart';
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

/// What the plan form checks before it saves.
mixin MeasurementPlanFormChecks on MeasurementPlanFormScope {
  /// The active plan of the kind shown among [plans], when there is one.
  MeasurementPlan? activePlanOf(List<MeasurementPlan> plans) {
    for (final item in plans) {
      if (item.kind == kind && item.stoppedAt == null) return item;
    }
    return null;
  }

  /// Whether the form can be saved; when not, shows why and says false.
  bool isReady(MeasurementPlan? plan) {
    if (days.isEmpty) {
      setState(() => errorKey = 'measurements.days_required');
      return false;
    }
    if (!PlanLimits.isValidMissedAfter(missedAfter)) {
      setState(() => missedAfterChecked = true);
      return false;
    }
    final times = <String>{for (final item in readings) item.clock};
    if (times.length != readings.length) {
      setState(() => errorKey = 'measurements.times_repeat');
      return false;
    }
    return true;
  }
}

/// «جدولة قياس» (new, [planId] null) or «تعديل جدولة القياس» of [planId].
///
/// An edit starts from the plan's latest version (a change waiting for
/// later, when there is one) and is saved against that version's number,
/// so a change made elsewhere meanwhile is refused, not overwritten.
class MeasurementPlanFormPage extends StatefulWidget {
  const MeasurementPlanFormPage({
    super.key,
    required this.circleId,
    this.planId,
  });

  final String circleId;
  final String? planId;

  @override
  State<MeasurementPlanFormPage> createState() => MeasurementPlanFormState();
}
