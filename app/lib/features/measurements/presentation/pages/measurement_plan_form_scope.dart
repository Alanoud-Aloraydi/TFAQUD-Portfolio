import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/models/plan_reading_draft.dart';
import 'package:app/features/measurements/presentation/models/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_page.dart';
import 'package:flutter/material.dart';

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
