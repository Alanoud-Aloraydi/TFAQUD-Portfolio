import 'dart:async';

import 'package:app/core/services/reminders/reminder_limits.dart';
import 'package:app/core/services/reminders/snooze_storage.dart';
import 'package:app/core/services/reminders/task_snooze.dart';
import 'package:flutter/foundation.dart';

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
