import 'package:flutter/material.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

class ScheduleFormData {
  ScheduleFormData({
    required this.time,
    required double dose,
    required Set<int> weekdays,
    required this.doseUnit,
    String? instructions,
  }) : doseController = TextEditingController(text: _number(dose)),
       instructionsController = TextEditingController(text: instructions),
       weekdays = {...weekdays};

  TimeOfDay time;
  DoseUnit doseUnit;
  final TextEditingController doseController;
  final TextEditingController instructionsController;
  final Set<int> weekdays;
  final FocusNode doseFocus = FocusNode();
  final FocusNode weekdaysFocus = FocusNode();

  void dispose() {
    doseController.dispose();
    instructionsController.dispose();
    doseFocus.dispose();
    weekdaysFocus.dispose();
  }

  static String _number(double value) =>
      value.toString().replaceFirst(RegExp(r'\.0$'), '');
}
