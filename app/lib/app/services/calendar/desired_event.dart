part of 'package:app/app/services/calendar_sync.dart';

/// One event this feature wants on the phone's calendar, before it exists.
class _DesiredEvent {
  const _DesiredEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.reminders,
    required this.zone,
    this.note,
    this.place,
    this.recurrence,
    this.until,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final List<Duration> reminders;

  /// The patient's IANA zone: the calendar keeps the event, and repeats
  /// it, at the patient's wall clock there, across DST, wherever this
  /// phone is.
  final String zone;
  final String? note;
  final String? place;
  final RecurrenceRule? recurrence;

  /// The moment a repeating event repeats up to ([recurrence] ends there).
  final DateTime? until;
}
