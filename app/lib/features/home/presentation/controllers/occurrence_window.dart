import 'package:app/core/utils/overdue_window.dart';
import 'package:app/core/utils/schedule_day.dart';

/// The days «اليوم» reads doses for, in calendar days of the patient's
/// [today]: from the first overdue day to a month ahead.
({DateTime from, DateTime to}) occurrenceWindow(DateTime today) =>
    (from: overdueStart(today), to: addDays(today, 30));
