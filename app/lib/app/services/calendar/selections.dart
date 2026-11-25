part of 'package:app/app/services/calendar_sync.dart';

/// Which circles and categories are turned on.
mixin _CalendarSelections on _CalendarLifecycle {
  /// What the phone allows the app to do with its calendar, asked of the
  /// system and not of our saved choices. «Add Only» on iOS is
  /// [AppPermission.partial]: events can be written but not deleted.
  Future<AppPermission> permission() async {
    try {
      return switch (await _calendar.hasPermissions()) {
        CalendarPermissionStatus.granted => AppPermission.granted,
        CalendarPermissionStatus.writeOnly => AppPermission.partial,
        CalendarPermissionStatus.notDetermined => AppPermission.notAsked,
        _ => AppPermission.denied,
      };
    } on Exception {
      return AppPermission.denied;
    }
  }

  /// Asks the system for calendar access, which it shows only while the
  /// answer is still [AppPermission.askable]; what it allows afterwards.
  /// Called when the person turns the copy on, so the question is theirs.
  Future<AppPermission> requestPermission() async {
    final AppPermission current = await permission();
    if (!current.askable) return current;
    _calendar.autoPermissions = AutoPermissionMode.full;
    try {
      await _calendar.requestPermissions();
    } on Exception {
      return current;
    }
    return permission();
  }

  /// Whether this circle's category is turned on.
  Future<bool> isEnabled(String circleId, CalendarSyncCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    return selections.contains(_selectionKey(circleId, category));
  }

  /// Turns one circle's category on or off; [refresh] reconciles the
  /// calendar to match every selection right after: its events are added,
  /// or taken off the phone's calendar.
  Future<void> setEnabled(
    String circleId,
    CalendarSyncCategory category,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    final String key = _selectionKey(circleId, category);
    final bool changed = value ? selections.add(key) : selections.remove(key);
    if (!changed) return;
    await prefs.setStringList(_selectionsKey, selections.toList());
    if (value) _calendar.autoPermissions = AutoPermissionMode.full;
    await refresh();
  }

  /// Whether this circle is copied to the calendar at all.
  Future<bool> isCircleEnabled(String circleId) async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    return CalendarSyncCategory.values.any(
      (CalendarSyncCategory category) =>
          selections.contains(_selectionKey(circleId, category)),
    );
  }

  /// Turns the whole circle on or off: its doses, its measurement times and
  /// its appointments together. One write and one [refresh], rather than
  /// one of each per kind.
  Future<void> setCircleEnabled(String circleId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final selections = await _selections(prefs);
    bool changed = false;
    for (final CalendarSyncCategory category in CalendarSyncCategory.values) {
      final String key = _selectionKey(circleId, category);
      changed |= value ? selections.add(key) : selections.remove(key);
    }
    if (!changed) return;
    await prefs.setStringList(_selectionsKey, selections.toList());
    if (value) _calendar.autoPermissions = AutoPermissionMode.full;
    await refresh();
  }
}
