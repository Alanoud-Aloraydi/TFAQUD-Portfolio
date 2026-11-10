import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

/// Holds schedule form values for this workflow.
///
/// The weekdays and the number of days are both kept while the person
/// switches between «أسبوعي» and «كل كم يوم», so switching back loses
/// nothing; only the chosen [repeat]'s days are saved. The form offers
/// those two: a monthly schedule saved before comes in as every 30 days,
/// with its days of the month in [formerMonthDays] to show what it was.
class ScheduleFormData {
  ScheduleFormData({
    required this.time,
    required double dose,
    required Set<int> weekdays,
    required this.doseUnit,
    String? instructions,
    this.repeat = ScheduleRepeat.weekly,
    this.intervalDays = defaultIntervalDays,
    this.formerMonthDays = const <int>[],
  }) : assert(repeat != ScheduleRepeat.monthly),
       doseController = TextEditingController(text: _number(dose)),
       instructionsController = TextEditingController(text: instructions),
       weekdays = {...weekdays};

  /// Where «كل كم يوم» starts: every other day, the most common answer
  /// after every day.
  static const int defaultIntervalDays = 2;

  /// Where a monthly schedule saved before starts.
  static const int monthlyIntervalDays = 30;

  TimeOfDay time;
  DoseUnit doseUnit;

  /// [ScheduleRepeat.weekly] or [ScheduleRepeat.interval].
  ScheduleRepeat repeat;
  final TextEditingController doseController;
  final TextEditingController instructionsController;
  final Set<int> weekdays;

  /// Every how many days, 1 to [maxIntervalDays].
  int intervalDays;

  /// The days of the month of the monthly schedule this was; empty for
  /// any other.
  final List<int> formerMonthDays;

  /// Whether the chosen [repeat] has its days: a weekday at least, or a
  /// number of days (always).
  bool get hasDays => repeat != ScheduleRepeat.weekly || weekdays.isNotEmpty;
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
