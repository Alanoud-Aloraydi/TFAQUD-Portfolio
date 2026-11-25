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
class CalendarSync extends _CalendarState
    with _CalendarLifecycle, _CalendarSelections {
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
}
