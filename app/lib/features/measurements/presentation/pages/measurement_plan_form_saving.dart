import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_filling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Saves the plan the form describes.
mixin MeasurementPlanFormSaving
    on MeasurementPlanFormScope, MeasurementPlanFormChecks {
  Future<void> save(MeasurementPlan? plan) async {
    if (!isReady(plan)) return;
    final draft = _draft();
    setState(() {
      saving = true;
      errorKey = null;
    });
    final cubit = context.read<MeasurementPlansCubit>();
    final String? failure = plan == null
        ? await cubit.create(draft)
        : await cubit.revise(plan, draft);
    if (!mounted) return;
    if (failure == null) {
      AppToast.show(context, 'toast.measurement_plan_saved');
      context.pop(true);
    } else {
      setState(() => saving = false);
      _refused(failure);
    }
  }

  /// A refusal that belongs to a row is said under it; any other is a toast.
  void _refused(String key) =>
      key == 'measurements.days_required' || key == 'measurements.times_repeat'
      ? setState(() => errorKey = key)
      : AppToast.show(context, key, kind: ToastKind.error);

  MeasurementPlanDraft _draft() {
    final sorted = readings.toList()
      ..sort((a, b) => a.clock.compareTo(b.clock));
    return MeasurementPlanDraft(
      kind: kind,
      times: <MeasurementTime>[
        for (final item in sorted)
          MeasurementTime(
            time: item.clock,
            measurementState: item.measurementState,
          ),
      ],
      weekdays: days.toList()..sort(),
      startsOn: start,
      missedAfterMinutes: missedAfter!,
    );
  }
}

/// What the plan form holds while it is open: the kind shown, a schedule
/// for each kind, the normal ranges, and the save and error flags.
mixin MeasurementPlanFormScope on State<MeasurementPlanFormPage> {
  MeasurementKind kind = MeasurementKind.glucose;

  /// Made on first use, where the patient's today can be read: a new plan
  /// starts on it.
  late final Map<MeasurementKind, PlanScheduleDraft> schedules = {
    MeasurementKind.glucose: PlanScheduleDraft(<PlanReadingDraft>[
      PlanReadingDraft(const TimeOfDay(hour: 7, minute: 30), 'fasting'),
    ], PatientClockScope.of(context).today()),
    MeasurementKind.bp: PlanScheduleDraft(<PlanReadingDraft>[
      PlanReadingDraft(const TimeOfDay(hour: 8, minute: 0), 'morning'),
    ], PatientClockScope.of(context).today()),
  };

  PlanScheduleDraft get schedule => schedules[kind]!;
  List<PlanReadingDraft> get readings => schedule.readings;
  Set<int> get days => schedule.days;
  DateTime get start => schedule.start;
  set start(DateTime value) => schedule.start = value;
  int? get missedAfter => schedule.missedAfter;
  set missedAfter(int? value) => schedule.missedAfter = value;

  /// «المعدل الطبيعي» of the patient: fixed, chosen by the medical file.
  late final MeasurementRangesCubit ranges;
  bool initialized = false;
  bool saving = false;
  String? errorKey;
  bool missedAfterChecked = false;

  /// Runs [change] and clears the error shown, as any edit of a reading.
  void edit(VoidCallback change) => setState(() {
    change();
    errorKey = null;
  });
}
