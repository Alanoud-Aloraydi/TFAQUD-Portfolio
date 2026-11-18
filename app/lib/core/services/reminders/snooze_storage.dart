import 'dart:convert';

import 'package:app/core/services/reminders/snooze_codec.dart';
import 'package:app/core/services/reminders/task_snooze.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _snoozesKey = 'dose_card_snoozes';

/// The tasks put off that the phone kept, or null when it kept none (or
/// something unreadable).
Future<Map<String, SnoozeSlot>?> loadSnoozes() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? raw = prefs.getString(_snoozesKey);
  if (raw == null) return null;
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decodeSnoozes(decoded);
  } on FormatException {
    return null;
  }
}

/// Keeps [entries] on the phone; none at all removes what was kept.
Future<void> saveSnoozes(Map<String, SnoozeSlot> entries) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (entries.isEmpty) {
    await prefs.remove(_snoozesKey);
    return;
  }
  await prefs.setString(_snoozesKey, encodeSnoozes(entries));
}
