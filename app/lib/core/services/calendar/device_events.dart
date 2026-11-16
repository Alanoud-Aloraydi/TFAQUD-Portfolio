part of '../calendar_sync.dart';

/// Access, making and deleting events on the device calendar.
extension _CalendarDevice on _CalendarState {
  /// Whether this app may delete events, which takes full calendar access.
  /// With add-only access (iOS), or none asked yet, it asks once per run of
  /// the app; the person turned the calendar on, so the question is theirs.
  Future<bool> _fullAccess() async {
    try {
      CalendarPermissionStatus status = await _calendar.hasPermissions();
      if (status == CalendarPermissionStatus.granted) return true;
      final bool canAsk =
          status == CalendarPermissionStatus.writeOnly ||
          status == CalendarPermissionStatus.notDetermined;
      if (!canAsk || _askedForFull) return false;
      _askedForFull = true;
      status = await _calendar.requestPermissions();
      return status == CalendarPermissionStatus.granted;
    } on Exception {
      return false;
    }
  }

  /// Makes [event] in the calendar [calendarId] (null: the phone's default
  /// one); its id, or null when it could not be made.
  Future<String?> _createEvent(_DesiredEvent event, String? calendarId) async {
    try {
      return await _calendar.createEvent(
        calendarId: calendarId,
        title: event.title,
        startDate: event.start,
        endDate: event.end,
        description: event.note,
        location: event.place,
        timeZone: event.zone,
        availability: EventAvailability.free,
        recurrenceRule: event.recurrence,
        reminders: event.reminders,
      );
    } on Exception {
      // No calendar access, or the device refused it; try again next sync.
      return null;
    }
  }

  /// Deletes the event of [key]; true when it is off the calendar (or was
  /// already), false when it should be tried again later. An event the
  /// calendar no longer knows by its id is looked for by its title at its
  /// first start; none of [known] (the ids of the other events) is taken.
  Future<bool> _delete(String key, _SavedEvent event, Set<String> known) async {
    try {
      await _deleteById(event.id, repeats: _repeats(key));
      return true;
    } on DeviceCalendarException catch (error) {
      if (error.errorCode != DeviceCalendarError.notFound) return false;
    } on Exception {
      return false;
    }
    final String? title = event.title;
    final DateTime? start = event.start;
    if (title == null || start == null) return true;
    try {
      final List<Event> found = await _calendar.listEvents(
        start,
        start.add(const Duration(minutes: 1)),
      );
      for (final Event item in found) {
        if (item.title != title || known.contains(item.eventId)) continue;
        await _deleteById(
          item.isRecurring ? item.eventId : item.instanceId,
          repeats: item.isRecurring,
        );
      }
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> _deleteById(String id, {required bool repeats}) => repeats
      ? _calendar.deleteRecurring(id, EventSpan.allEvents)
      : _calendar.deleteEvent(instanceId: id);
}
