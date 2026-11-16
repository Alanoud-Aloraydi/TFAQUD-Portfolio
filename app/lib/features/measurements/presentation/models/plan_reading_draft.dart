import 'package:flutter/material.dart';

/// One reading time and its glucose «حالة القياس».
class PlanReadingDraft {
  PlanReadingDraft(this.time, this.measurementState);

  TimeOfDay time;
  String? measurementState;
}
