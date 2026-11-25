part of 'package:app/app/services/calendar_sync.dart';

/// Starting a reconciliation, and ending them all on sign-out.
mixin _CalendarLifecycle on _CalendarState {
  /// The circles to mirror, from now on. Called when the home data loads.
  Future<void> sync(List<ReminderCircle> circles) {
    _circles = List<ReminderCircle>.unmodifiable(circles);
    _synced = true;
    return refresh();
  }

  /// Recomputes the desired events and reconciles the calendar to match.
  /// One reading runs at a time; a call during it makes one more right after.
  Future<void> refresh() => _runner.run();

  /// Removes every event this feature made, with the app's own calendar:
  /// the person signed out. The switches themselves are kept, so signing
  /// back in puts the events the person had asked for back by itself; they
  /// are per circle, so another account on this phone sees none of them.
  /// An event the calendar would not delete now is deleted at the next
  /// refresh.
  Future<void> clear() async {
    _session++;
    _circles = const <ReminderCircle>[];
    _synced = false;
    _runner.dropPending();
    final prefs = await SharedPreferences.getInstance();
    await _removeAll(prefs);
  }
}
