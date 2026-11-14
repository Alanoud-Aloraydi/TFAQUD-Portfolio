import 'package:flutter/material.dart';

/// One reading time and its glucose «حالة القياس».
class MeasurementPlanReadingField {
  MeasurementPlanReadingField(this.time, this.measurementState);

  TimeOfDay time;
  String? measurementState;
}
