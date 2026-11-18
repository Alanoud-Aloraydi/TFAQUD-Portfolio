import 'dart:async';

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/reminder_limits.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/services/reminders/reminder_permission.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/services/reminders/snooze_ledger.dart';
import 'package:app/core/services/reminders/task_snooze.dart';
import 'package:app/core/services/reminders/tell_circle.dart';

/// Puts a task off: sets its reminder at the new time, in the task's own
/// slot of the [ledger].
class SnoozePutter {
  SnoozePutter({
    required this.ledger,
    required this.phone,
    required this.permission,
    this.share,
  });

  final SnoozeLedger ledger;
  final PhoneNotifications phone;
  final ReminderPermission permission;

  /// Tells the circle of a task put off; null in tests of one phone.
  final Future<void> Function(SnoozeShare snooze)? share;

  /// Puts the task of [key] off to [snooze]'s moment, in the task's own
  /// slot: put off again, it keeps one reminder, at the new time. Its
  /// reminder at its planned time, still to come when put off early, is
  /// taken off, and is not set again while the snooze waits. Recording the
  /// task takes the snooze off ([settleSnoozes]). The circle is told
  /// ([tellCircle]).
  Future<void> put({
    required String key,
    required Duration after,
    required TaskSnooze snooze,
    required String title,
    required String body,
  }) async {
    await ledger.read();
    final DateTime now = ledger.now().toUtc();
    ledger.entries.removeWhere(
      (String _, SnoozeSlot entry) => !entry.snooze.at.isAfter(now),
    );
    final SnoozeSlot? earlier = ledger.entries.remove(key);
    final int slot = earlier?.slot ?? ledger.freeSlot();
    ledger.entries[key] = (snooze: snooze, slot: slot);
    // A snooze can be the first reminder this phone sets (a day whose tasks
    // have all passed asks nothing), and without the permission iOS drops
    // it in silence. iOS asks the person only the first time.
    await permission.ask(request: true);
    final Map<int, String> pending = await phone.pending();
    for (final MapEntry<int, String> entry in pending.entries) {
      if (isReminderPayload(entry.value) &&
          snoozeTarget(entry.value)?.$1 == key) {
        await phone.cancel(entry.key);
      }
    }
    await phone.schedule(
      ScheduledNotification(
        id: cardSnoozeIdBase + slot,
        at: snooze.at,
        title: title,
        body: body,
        // It can be put off again, the same as the reminder it came from.
        payload: payloadWithText(
          '${snooze.task.payloadPrefix}${snooze.circleId}',
          title,
          body,
          snoozeKey: key,
          subject: snooze.subject,
        ),
        thread: snooze.circleId,
        snoozable: true,
      ),
    );
    await ledger.save();
    unawaited(tellCircle(share, key, after));
  }
}
