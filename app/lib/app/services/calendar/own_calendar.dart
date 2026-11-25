part of 'package:app/app/services/calendar_sync.dart';

/// The app's own calendar on the phone.
extension _CalendarOwn on _CalendarState {
  /// The id of the app's own calendar, made the first time it is needed;
  /// null when the phone will not make one (no full access, or no calendar
  /// account that takes a new calendar): the events then go in the phone's
  /// default calendar.
  ///
  /// A «تفقُد» calendar this install did not make was left by an earlier
  /// one (deleting the app leaves its calendar): it is deleted, with its
  /// events, before a new one is made.
  Future<String?> _ownCalendar(SharedPreferences prefs) async {
    final String? known = prefs.getString(_calendarKey);
    if (known != null) return known;
    if (!await _fullAccess()) return null;
    try {
      for (final Calendar left in await _calendar.listCalendars()) {
        if (left.name == ServiceTexts.calendarName && !left.readOnly) {
          await _calendar.deleteCalendar(left.id);
        }
      }
      final String id = await _calendar.createCalendar(
        name: ServiceTexts.calendarName,
        colorHex: _calendarColor,
      );
      await prefs.setString(_calendarKey, id);
      return id;
    } on Exception {
      return null;
    }
  }

  /// The app's calendar was deleted (in the Calendar app, say), and its
  /// events with it: they are forgotten here, so they are made again.
  Future<void> _forgetDeletedCalendar(
    SharedPreferences prefs,
    Map<String, _SavedEvent> saved,
  ) async {
    final String? own = prefs.getString(_calendarKey);
    if (own == null || !await _fullAccess()) return;
    try {
      final List<Calendar> calendars = await _calendar.listCalendars();
      if (calendars.any((Calendar calendar) => calendar.id == own)) return;
    } on Exception {
      return;
    }
    saved.removeWhere((String _, _SavedEvent e) => e.calendar == own);
    await prefs.remove(_calendarKey);
  }

  /// Deletes the app's calendar with every event on it; true when it is
  /// gone (or was already).
  Future<bool> _deleteOwnCalendar(SharedPreferences prefs) async {
    final String? own = prefs.getString(_calendarKey);
    if (own == null) return true;
    try {
      await _calendar.deleteCalendar(own);
    } on DeviceCalendarException catch (error) {
      if (error.errorCode != DeviceCalendarError.notFound) return false;
    } on Exception {
      return false;
    }
    await prefs.remove(_calendarKey);
    return true;
  }
}
