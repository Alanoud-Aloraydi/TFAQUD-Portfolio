part of 'package:app/app/services/calendar_sync.dart';

/// The map of the events this phone made, kept in preferences.
extension _CalendarSaved on _CalendarState {
  Map<String, _SavedEvent> _readSaved(SharedPreferences prefs) {
    final String? raw = prefs.getString(_eventsKey);
    if (raw == null) return <String, _SavedEvent>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, _SavedEvent>{};
      return <String, _SavedEvent>{
        for (final MapEntry<String, dynamic> entry in decoded.entries)
          if (_SavedEvent.fromJson(entry.value) case final _SavedEvent event)
            entry.key: event,
      };
    } on FormatException {
      return <String, _SavedEvent>{};
    }
  }

  Future<void> _writeSaved(
    SharedPreferences prefs,
    Map<String, _SavedEvent> saved,
  ) async {
    if (saved.isEmpty) {
      await prefs.remove(_eventsKey);
      return;
    }
    await prefs.setString(
      _eventsKey,
      jsonEncode(<String, Map<String, String>>{
        for (final MapEntry<String, _SavedEvent> entry in saved.entries)
          entry.key: entry.value.toJson(),
      }),
    );
  }
}
