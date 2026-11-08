import 'package:flutter/material.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';

/// Holds schedule form values for this workflow.
///
/// The weekdays and the month days are both kept while the person switches
/// between «أسبوعي» and «شهري», so switching back loses nothing; only the
/// chosen [repeat]'s days are saved.
class ScheduleFormData {
  ScheduleFormData({
    required this.time,
    required double dose,
    required Set<int> weekdays,
    required this.doseUnit,
    String? instructions,
    this.repeat = ScheduleRepeat.weekly,
    Set<int> monthDays = const <int>{},
  }) : doseController = TextEditingController(text: _number(dose)),
       instructionsController = TextEditingController(text: instructions),
       weekdays = {...weekdays},
       monthDays = {...monthDays};

  TimeOfDay time;
  DoseUnit doseUnit;
  ScheduleRepeat repeat;
  final TextEditingController doseController;
  final TextEditingController instructionsController;
  final Set<int> weekdays;

  /// Days of the month, 1 to 31.
  final Set<int> monthDays;

  /// The days of the chosen [repeat], empty when none is chosen yet.
  Set<int> get chosenDays => switch (repeat) {
    ScheduleRepeat.weekly => weekdays,
    ScheduleRepeat.monthly => monthDays,
  };
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
