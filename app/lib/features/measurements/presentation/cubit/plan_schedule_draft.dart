import 'package:app/core/constants/plan_limits.dart';
import 'package:flutter/material.dart';

/// The schedule of one kind: glucose and blood pressure each keep their own
/// times, days, start and missed-after wait while the form switches between them, and
/// only the kind shown is saved.
class PlanScheduleDraft {
  PlanScheduleDraft(this.readings, this.start);

  /// Several planned readings can share the same day.
  static const int maxReadings = 6;

  /// The reading times of a day, like a medicine's dose times: one or more,
  /// up to [maxReadings], each with its own
  /// glucose measurement state.
  final List<PlanReadingDraft> readings;
  final Set<int> days = {1, 2, 3, 4, 5, 6, 7};

  /// The first day, on the patient's calendar.
  DateTime start;
  int? missedAfter = PlanLimits.defaultMissedAfterMinutes;
}

/// One reading time and its glucose «حالة القياس».
class PlanReadingDraft {
  PlanReadingDraft(this.time, this.measurementState);

  TimeOfDay time;
  String? measurementState;

  /// The time as the server writes it: «07:30».
  String get clock =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
