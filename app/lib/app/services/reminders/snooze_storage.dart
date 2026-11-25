import 'dart:convert';

import 'package:app/app/services/reminders/reminder_limits.dart';
import 'package:app/app/services/reminders/snoozed_task.dart';
import 'package:app/app/services/reminders/task_snooze.dart';
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

/// The tasks put off that [decoded] holds, by their keys; an entry that is
/// not whole is left out.
Map<String, SnoozeSlot> decodeSnoozes(Map<String, dynamic> decoded) {
  final Map<String, SnoozeSlot> entries = <String, SnoozeSlot>{};
  for (final MapEntry<String, dynamic> entry in decoded.entries) {
    final Object? value = entry.value;
    if (value is! Map<String, dynamic>) continue;
    final Object? at = value['at'];
    final Object? slot = value['slot'];
    final Object? circleId = value['circle'];
    final Object? subject = value['subject'];
    final DateTime? moment = at is String ? DateTime.tryParse(at) : null;
    final SnoozedTask? task = SnoozedTask.values
        .where((SnoozedTask item) => item.name == value['task'])
        .firstOrNull;
    if (moment == null ||
        slot is! int ||
        circleId is! String ||
        subject is! String ||
        task == null) {
      continue;
    }
    if (slot < 0 || slot >= maxCardSnoozes) continue;
    entries.putIfAbsent(
      entry.key,
      () => (
        snooze: TaskSnooze(
          circleId: circleId,
          task: task,
          subject: subject,
          at: moment.toUtc(),
        ),
        slot: slot,
      ),
    );
  }
  return entries;
}

/// The text kept on the phone for [entries].
String encodeSnoozes(Map<String, SnoozeSlot> entries) =>
    jsonEncode(<String, Object>{
      for (final MapEntry<String, SnoozeSlot> entry in entries.entries)
        entry.key: <String, Object>{
          'at': entry.value.snooze.at.toUtc().toIso8601String(),
          'slot': entry.value.slot,
          'circle': entry.value.snooze.circleId,
          'task': entry.value.snooze.task.name,
          'subject': entry.value.snooze.subject,
        },
    });
