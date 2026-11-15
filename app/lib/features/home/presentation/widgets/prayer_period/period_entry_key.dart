import 'package:app/core/services/reminders/item_keys.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entries.dart';

/// The key of an entry's item, as a tapped notification names it
/// (item_keys.dart): a dose and a reading by their snooze key, a visit by
/// its circle and id.
String periodEntryKey(PeriodEntry entry, String circleId) => switch (entry) {
  PeriodEntry(dose: final dose?) => doseSnoozeKey(circleId, dose),
  PeriodEntry(measurement: final task?) => measurementSnoozeKey(circleId, task),
  PeriodEntry(visit: final visit?) => appointmentItemKey(circleId, visit.id),
  _ => '',
};
