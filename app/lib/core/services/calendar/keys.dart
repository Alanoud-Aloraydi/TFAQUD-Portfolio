part of '../calendar_sync.dart';

/// The keys of the selections and of the events they make.
extension _CalendarKeys on _CalendarState {
  String _selectionKey(String circleId, CalendarSyncCategory category) =>
      '$circleId:${category.name}';

  /// A key for one event of [circle]'s [category]: «v2:c-1:doses:…».
  String _eventKey(
    ReminderCircle circle,
    CalendarSyncCategory category,
    String rest,
  ) => '$_keyVersion:${_selectionKey(circle.id, category)}:$rest';

  Future<Set<String>> _selections(SharedPreferences prefs) async =>
      (prefs.getStringList(_selectionsKey) ?? const <String>[]).toSet();
}
