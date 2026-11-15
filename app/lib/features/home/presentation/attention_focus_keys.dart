import 'package:app/core/services/reminders/item_keys.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/home/presentation/today_snapshot.dart';

/// Every item of the «يحتاج انتباهك» box of [snapshot], as a tapped
/// notification names it (item_keys.dart): its doses, its measurements and
/// its visits.
Set<String> attentionFocusKeys(TodaySnapshot snapshot, String circleId) =>
    <String>{
      for (final dose in snapshot.medications.attention)
        doseSnoozeKey(circleId, dose),
      for (final task in snapshot.overdueMeasurements)
        measurementSnoozeKey(circleId, task),
      for (final item in snapshot.overdueAppointments)
        appointmentItemKey(circleId, item.id),
    };
