import 'dart:async';
import 'dart:convert';

import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/reminders/reminder_limits.dart';
import 'package:app/app/services/reminders/reminder_permission.dart';
import 'package:app/app/services/reminders/reminders_enabled.dart';
import 'package:app/core/reminders/task_snooze.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tasks put off, by [doseSnoozeKey] or [measurementSnoozeKey], the
/// first put off first. Kept on the phone, so a card still shows its time
/// after the app is opened again.
class SnoozeLedger {
  SnoozeLedger(this.now);

  final DateTime Function() now;
  final Map<String, SnoozeSlot> entries = <String, SnoozeSlot>{};
  final ValueNotifier<Map<String, TaskSnooze>> published =
      ValueNotifier<Map<String, TaskSnooze>>(const <String, TaskSnooze>{});
  Future<void>? _reading;
  Timer? _ends;

  /// Reads the tasks put off once, when first needed.
  Future<void> read() => _reading ??= _load();

  Future<void> _load() async {
    final Map<String, SnoozeSlot>? stored = await loadSnoozes();
    if (stored == null) return;
    for (final MapEntry<String, SnoozeSlot> entry in stored.entries) {
      entries.putIfAbsent(entry.key, () => entry.value);
    }
    publish();
  }

  Future<void> save() async {
    publish();
    await saveSnoozes(entries);
  }

  Future<void> drop() async {
    await read();
    entries.clear();
    await save();
  }

  /// A slot no task put off uses; with all of them used, the one put off
  /// first gives up its slot (its reminder is replaced).
  int freeSlot() {
    final Set<int> used = <int>{
      for (final SnoozeSlot entry in entries.values) entry.slot,
    };
    for (int slot = 0; slot < maxCardSnoozes; slot++) {
      if (!used.contains(slot)) return slot;
    }
    final String first = entries.keys.first;
    return entries.remove(first)!.slot;
  }

  /// Tells the cards and the calendar which tasks are put off, each until
  /// it came.
  void publish() {
    final DateTime moment = now().toUtc();
    published.value = Map<String, TaskSnooze>.unmodifiable(<String, TaskSnooze>{
      for (final MapEntry<String, SnoozeSlot> entry in entries.entries)
        if (entry.value.snooze.at.isAfter(moment))
          entry.key: entry.value.snooze,
    });
    _ends?.cancel();
    _ends = null;
    if (published.value.isEmpty) return;
    final DateTime next = published.value.values
        .map((TaskSnooze snooze) => snooze.at)
        .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
    _ends = Timer(
      next.difference(moment) + const Duration(seconds: 1),
      publish,
    );
  }
}

/// Whether a task put off with «ذكّرني لاحقًا» can come again on this
/// phone: the person still wants the reminders ([enabled]), and the phone
/// lets them through. With [ask], a phone never asked asks now and its
/// answer counts; without it, a phone never asked still counts as yes,
/// since putting the task off asks it.
Future<bool> remindersAllowed(
  RemindersEnabled enabled,
  ReminderPermission permission, {
  required bool ask,
}) async {
  if (!enabled.on.value) return false;
  final AppPermission allowed = await permission.ask(request: ask);
  return allowed.usable || (!ask && allowed == AppPermission.notAsked);
}

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
