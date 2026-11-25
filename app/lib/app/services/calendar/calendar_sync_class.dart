part of 'package:app/app/services/calendar_sync.dart';

/// Mirrors doses, measurement times and appointments onto the phone's own
/// Calendar app, as a backup to the reminders.
///
/// Off by default, turned on per circle and per category ([setEnabled]).
/// The events are visible to anything else with calendar access, unlike
/// the rest of this app's data.
///
/// They go in the app's own calendar ([ServiceTexts.calendarName]), so
/// signing out deletes all of them in one step. iOS tells an app nothing
/// when it is deleted, so a repeating event repeats two weeks ahead
/// ([_ahead]) and is made again while the app is used: after a deletion
/// its alerts stop within two weeks.
///
/// Nothing is stored on the server. Each phone keeps its own map of
/// "key it created" to "calendar event", and every [refresh] works out the
/// wanted set again from the plans on screen, deleting what is no longer
/// wanted — so an edited or stopped plan is never left behind.
///
/// A task put off with «ذكّرني لاحقًا» ([snoozes]) gets one more event at
/// its new time; it goes once the task is recorded or its time has come.
class CalendarSync extends _CalendarState {
  CalendarSync(
    MedicationsUseCase medications,
    MeasurementsUseCase measurements,
    AppointmentsUseCase appointments, {
    ValueListenable<Map<String, TaskSnooze>>? snoozes,
    DeviceCalendar? calendar,
    CalendarEventTexts? texts,
    DateTime Function()? clock,
  }) : super(
         medications,
         measurements,
         appointments,
         snoozes,
         calendar ?? DeviceCalendar.instance,
         texts ?? calendarEventTexts,
         clock ?? DateTime.now,
       ) {
    // Any accepted plan or appointment change reconciles the calendar right
    // away, not just on the next app resume.
    _medications.changes.listen((_) => unawaited(refresh()));
    _measurements.changes.listen((_) => unawaited(refresh()));
    _appointments.changes.listen((_) => unawaited(refresh()));
    // As does a task put off, or one whose new time came.
    snoozes?.addListener(() => unawaited(refresh()));
  }

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
