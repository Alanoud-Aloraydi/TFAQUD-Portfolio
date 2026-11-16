part of '../calendar_sync.dart';

/// What this phone remembers of an event it made: the calendar's id for
/// it, and its title and first start, to find it again when the calendar
/// gave it another id (a calendar of another account can, once it syncs);
/// the calendar it is in (null: the phone's default one); and, for a
/// repeating one, the day it repeats to. An older event has less.
class _SavedEvent {
  const _SavedEvent(
    this.id, {
    this.title,
    this.start,
    this.until,
    this.calendar,
  });

  final String id;
  final String? title;
  final DateTime? start;
  final DateTime? until;
  final String? calendar;

  static _SavedEvent? fromJson(Object? value) {
    if (value is String) return _SavedEvent(value);
    if (value is! Map<String, dynamic>) return null;
    final Object? id = value['id'];
    final Object? title = value['title'];
    final Object? start = value['start'];
    final Object? until = value['until'];
    final Object? calendar = value['calendar'];
    if (id is! String) return null;
    return _SavedEvent(
      id,
      title: title is String ? title : null,
      start: start is String ? DateTime.tryParse(start) : null,
      until: until is String ? DateTime.tryParse(until) : null,
      calendar: calendar is String ? calendar : null,
    );
  }

  Map<String, String> toJson() => <String, String>{
    'id': id,
    'title': ?title,
    'start': ?start?.toIso8601String(),
    'until': ?until?.toIso8601String(),
    'calendar': ?calendar,
  };
}
