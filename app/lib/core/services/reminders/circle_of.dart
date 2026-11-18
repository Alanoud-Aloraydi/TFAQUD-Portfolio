import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/utils/time_zones.dart';

/// The synced circle of [circleId] among [circles], for the words of its
/// reminders.
ReminderCircle circleOf(List<ReminderCircle> circles, String circleId) =>
    circles.where((ReminderCircle item) => item.id == circleId).firstOrNull ??
    ReminderCircle(
      id: circleId,
      name: '',
      viewerId: null,
      viewerIsPatient: false,
      timeZone: defaultPatientZone,
    );
