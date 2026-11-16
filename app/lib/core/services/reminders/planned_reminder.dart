import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/item_keys.dart';

/// One reminder of the plan before it gets its id.
class PlannedReminder {
  const PlannedReminder({
    required this.at,
    required this.circle,
    required this.title,
    required this.body,
    required this.prefix,
    this.snoozeKey,
    this.subject,
    this.appointmentId,
  });

  final DateTime at;
  final ReminderCircle circle;
  final String title;
  final String body;
  final String prefix;

  /// A dose's or measurement's, which can be put off.
  final String? snoozeKey;
  final String? subject;

  /// A visit's, so a tap on its reminder opens that visit.
  final String? appointmentId;

  bool get snoozable => snoozeKey != null;

  /// The start of its payload: its kind and circle, and a visit's id.
  String get payloadHead => switch (appointmentId) {
    final String id => '$prefix${circle.id}$appointmentIdMark$id',
    null => '$prefix${circle.id}',
  };
}
