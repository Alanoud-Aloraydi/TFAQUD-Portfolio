part of 'package:app/app/services/calendar_sync.dart';

/// Making the calendar match the wanted events.
extension _CalendarReconcile on _CalendarState {
  Future<void> _reconcile(
    SharedPreferences prefs,
    Map<String, _DesiredEvent> desired,
    Set<String> unread,
    int session,
  ) async {
    final Map<String, _SavedEvent> saved = _readSaved(prefs);
    await _forgetDeletedCalendar(prefs, saved);
    final String? own = prefs.getString(_calendarKey);
    // Not wanted any more; or wanted with other words, near the end of its
    // two weeks, or outside the app's calendar now that it has one: taken
    // off (and the wanted ones made again).
    final List<String> stale = <String>[];
    for (final MapEntry<String, _SavedEvent> entry in saved.entries) {
      final _DesiredEvent? wanted = desired[entry.key];
      final _SavedEvent event = entry.value;
      if (wanted != null
          ? wanted.title != event.title ||
                _endsSoon(event) ||
                (own != null && event.calendar != own)
          : !unread.contains(_groupOf(entry.key))) {
        stale.add(entry.key);
      }
    }
    if (stale.isNotEmpty && await _fullAccess()) {
      final Set<String> known = <String>{
        for (final _SavedEvent event in saved.values) event.id,
      };
      for (final String key in stale) {
        if (session != _session) return;
        if (await _delete(key, saved[key]!, known)) saved.remove(key);
      }
    }
    // The wanted events not on the calendar. One whose old event could not
    // be taken off yet stays as it is, until it can.
    final List<MapEntry<String, _DesiredEvent>> missing = desired.entries
        .where((MapEntry<String, _DesiredEvent> e) => !saved.containsKey(e.key))
        .toList();
    final String? calendarId = missing.isEmpty
        ? null
        : await _ownCalendar(prefs);
    if (session != _session) return;
    for (final MapEntry<String, _DesiredEvent> entry in missing) {
      if (session != _session) return;
      final String? id = await _createEvent(entry.value, calendarId);
      if (id != null) {
        saved[entry.key] = _SavedEvent(
          id,
          title: entry.value.title,
          start: entry.value.start,
          until: entry.value.until,
          calendar: calendarId,
        );
      }
    }
    if (session != _session) return;
    await _writeSaved(prefs, saved);
    // Nothing on the app's calendar any more: it goes too, until needed.
    if (saved.isEmpty &&
        prefs.getString(_calendarKey) != null &&
        await _fullAccess()) {
      await _deleteOwnCalendar(prefs);
    }
  }
}
