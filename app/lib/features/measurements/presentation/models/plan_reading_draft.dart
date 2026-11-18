import 'package:flutter/material.dart';

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
