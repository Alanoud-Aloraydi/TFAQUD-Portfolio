import 'dart:async';

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/services/reminders/reminder_permission.dart';
import 'package:app/core/services/reminders/reminders_enabled.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/services/reminders/snooze_allowed.dart';
import 'package:app/core/services/reminders/snooze_ledger.dart';
import 'package:app/core/services/reminders/snooze_reminder.dart';
import 'package:app/core/services/reminders/task_snooze.dart';
import 'package:app/core/services/reminders/tell_circle.dart';

/// Puts a task off: sets its reminder at the new time, in the task's own
/// slot of the [ledger].
class SnoozePutter {
  SnoozePutter({
    required this.ledger,
    required this.phone,
    required this.permission,
    required this.enabled,
    this.share,
  });

  final SnoozeLedger ledger;
  final PhoneNotifications phone;
  final ReminderPermission permission;

  /// The person's own switch: off, nothing is put off.
  final RemindersEnabled enabled;

  /// Tells the circle of a task put off; null in tests of one phone.
  final Future<void> Function(SnoozeShare snooze)? share;

  /// Puts the task of [key] off to [snooze]'s moment, in the task's own
  /// slot: put off again, it keeps one reminder, at the new time. Its
  /// reminder at its planned time, still to come when put off early, is
  /// taken off, and is not set again while the snooze waits. Recording the
  /// task takes the snooze off ([settleSnoozes]). The circle is told
  /// ([tellCircle]). False, and nothing changes, while the reminders are
  /// off or the phone refuses them ([remindersAllowed]).
  Future<bool> put({
    required String key,
    required Duration after,
    required TaskSnooze snooze,
    required String title,
    required String body,
  }) async {
    // A snooze can be the first reminder this phone sets (a day whose tasks
    // have all passed asks nothing), so it asks; iOS asks only once.
    if (!await remindersAllowed(enabled, permission, ask: true)) return false;
    await ledger.read();
    final DateTime now = ledger.now().toUtc();
    ledger.entries.removeWhere(
      (String _, SnoozeSlot entry) => !entry.snooze.at.isAfter(now),
    );
    final SnoozeSlot? earlier = ledger.entries.remove(key);
    final int slot = earlier?.slot ?? ledger.freeSlot();
    ledger.entries[key] = (snooze: snooze, slot: slot);
    final Map<int, String> pending = await phone.pending();
    for (final MapEntry<int, String> entry in pending.entries) {
      if (isReminderPayload(entry.value) &&
          snoozeTarget(entry.value)?.$1 == key) {
        await phone.cancel(entry.key);
      }
    }
    await setSnoozeReminder(
      phone,
      key: key,
      slot: slot,
      snooze: snooze,
      title: title,
      body: body,
    );
    await ledger.save();
    unawaited(tellCircle(share, key, after));
    return true;
  }
}
