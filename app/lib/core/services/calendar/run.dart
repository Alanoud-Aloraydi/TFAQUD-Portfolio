part of '../calendar_sync.dart';

/// One reconciliation: what is wanted, then what is on the calendar.
extension _CalendarRun on _CalendarState {
  Future<void> _run() async {
    if (!_synced) return;
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    final int session = _session;
    final List<ReminderCircle> circles = _circles;
    final Map<String, _DesiredEvent> desired = <String, _DesiredEvent>{};
    // The circles' categories that could not be read now (offline, say):
    // their events stay as they are, rather than leaving the calendar until
    // the next reading.
    final Set<String> unread = <String>{};
    for (final ReminderCircle circle in circles) {
      for (final CalendarSyncCategory category in CalendarSyncCategory.values) {
        if (session != _session) return;
        final String selection = _selectionKey(circle.id, category);
        if (!selections.contains(selection)) continue;
        final bool read = switch (category) {
          CalendarSyncCategory.doses => await _collectDoses(circle, desired),
          CalendarSyncCategory.measurements => await _collectMeasurements(
            circle,
            desired,
          ),
          CalendarSyncCategory.appointments => await _collectAppointments(
            circle,
            desired,
          ),
        };
        if (!read) unread.add(selection);
      }
    }
    _collectSnoozes(circles, selections, desired);
    if (session != _session) return;
    await _reconcile(prefs, desired, unread, session);
  }

  /// Takes off every event this phone made: the app's whole calendar at
  /// once, then, one by one, any put in the phone's default calendar.
  Future<void> _removeAll(SharedPreferences prefs) async {
    final Map<String, _SavedEvent> saved = _readSaved(prefs);
    final String? own = prefs.getString(_calendarKey);
    if ((saved.isNotEmpty || own != null) && await _fullAccess()) {
      if (own != null && await _deleteOwnCalendar(prefs)) {
        saved.removeWhere((String _, _SavedEvent e) => e.calendar == own);
      }
      final Set<String> known = <String>{
        for (final _SavedEvent event in saved.values) event.id,
      };
      for (final String key in saved.keys.toList()) {
        if (await _delete(key, saved[key]!, known)) saved.remove(key);
      }
    }
    await _writeSaved(prefs, saved);
  }

  /// Whether a repeating event is near the end of its two weeks.
  bool _endsSoon(_SavedEvent event) {
    final DateTime? until = event.until;
    return until != null && until.difference(_now()) < _extendWithin;
  }
}
