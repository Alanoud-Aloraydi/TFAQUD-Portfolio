part of '../calendar_sync.dart';

/// What the rest of a put-off task's key starts with: its event is once,
/// not repeating.
const String _snoozePart = 'snooze';

const String _selectionsKey = 'calendar_sync_selections';
const String _eventsKey = 'calendar_sync_events';

/// The id of the app's own calendar, once made.
const String _calendarKey = 'calendar_sync_calendar';

/// The app's green («leaf»), for the calendar's dot.
const String _calendarColor = '#C4B5E0';

/// How far ahead a repeating event repeats.
const Duration _ahead = Duration(days: 14);

/// With less than this left, a refresh makes the event again, [_ahead]
/// from then: at most once a week.
const Duration _extendWithin = Duration(days: 7);

/// What the keys of this version start with. A key of an older version
/// is not wanted any more, so its event is replaced: v2 events were in
/// the default calendar and repeated with no end.
const String _keyVersion = 'v3';

/// A key of any version: «v2:…», «v3:…».
final RegExp _versioned = RegExp(r'^v\d+$');

/// The circle and category of a key of this version, «c-1:doses»;
/// null for an older key.
String? _groupOf(String key) {
  final List<String> parts = key.split(':');
  return parts.length > 3 && parts.first == _keyVersion
      ? '${parts[1]}:${parts[2]}'
      : null;
}

/// Whether the event of [key] repeats: everything but an appointment and
/// a task put off.
bool _repeats(String key) {
  final List<String> parts = key.split(':');
  return _versioned.hasMatch(parts.first)
      ? parts.length > 3 &&
            parts[2] != CalendarSyncCategory.appointments.name &&
            parts[3] != _snoozePart
      : !key.startsWith('appointment:');
}
