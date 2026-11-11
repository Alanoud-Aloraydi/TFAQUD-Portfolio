import 'package:app/core/utils/patient_clock.dart';

/// How many patient days before today a task can still be answered from
/// «اليوم» (taken, skipped, read or closed). Older ones leave the tab; the
/// server still accepts them and the records keep them.
const int overdueDays = 2;

/// The first patient day that still counts as overdue on [today], a
/// date-only value. Calendar arithmetic on the patient's own day, so it
/// holds across clock changes and whatever zone the phone is in.
DateTime overdueStart(DateTime today) =>
    addDays(scheduleDay(today), -overdueDays);
