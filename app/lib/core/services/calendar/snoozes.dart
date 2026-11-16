part of '../calendar_sync.dart';

/// The events of tasks put off.
extension _CalendarSnoozes on _CalendarState {
  /// One event at the new time of each dose or measurement put off, in a
  /// circle and category that are turned on, in the words of that task's
  /// own events.
  void _collectSnoozes(
    List<ReminderCircle> circles,
    Set<String> selections,
    Map<String, _DesiredEvent> desired,
  ) {
    final Map<String, TaskSnooze> snoozes =
        _snoozes?.value ?? const <String, TaskSnooze>{};
    for (final MapEntry<String, TaskSnooze> entry in snoozes.entries) {
      final TaskSnooze snooze = entry.value;
      final ReminderCircle? circle = circles
          .where((ReminderCircle item) => item.id == snooze.circleId)
          .firstOrNull;
      final CalendarSyncCategory category = switch (snooze.task) {
        SnoozedTask.dose => CalendarSyncCategory.doses,
        SnoozedTask.measurement => CalendarSyncCategory.measurements,
      };
      if (circle == null ||
          !selections.contains(_selectionKey(circle.id, category))) {
        continue;
      }
      final String? title = switch (snooze.task) {
        SnoozedTask.dose => _texts.dose(circle.id, snooze.subject),
        SnoozedTask.measurement => switch (MeasurementKind.values
            .where((MeasurementKind kind) => kind.name == snooze.subject)
            .firstOrNull) {
          final MeasurementKind kind => _texts.measurement(circle.id, kind),
          null => null,
        },
      };
      if (title == null) continue;
      final DateTime start = snooze.at.toLocal();
      // The moment is part of the key: put off again, the event moves.
      desired[_eventKey(
        circle,
        category,
        '$_snoozePart:${snooze.at.millisecondsSinceEpoch}:${entry.key}',
      )] = _DesiredEvent(
        title: title,
        note: snooze.task == SnoozedTask.dose ? _texts.doseNote() : null,
        zone: circle.timeZone,
        start: start,
        end: start.add(const Duration(minutes: 15)),
        reminders: const <Duration>[Duration.zero],
      );
    }
  }
}
