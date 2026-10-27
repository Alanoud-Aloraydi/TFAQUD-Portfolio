import 'package:flutter/material.dart';

class ScheduleFormData {
  ScheduleFormData({
    required this.time,
    required double dose,
    required Set<int> weekdays,
    String? instructions,
  }) : doseController = TextEditingController(text: _number(dose)),
       instructionsController = TextEditingController(text: instructions),
       weekdays = {...weekdays};

  TimeOfDay time;
  final TextEditingController doseController;
  final TextEditingController instructionsController;
  final Set<int> weekdays;

  void dispose() {
    doseController.dispose();
    instructionsController.dispose();
  }

  static String _number(double value) =>
      value.toString().replaceFirst(RegExp(r'\.0$'), '');
}
