import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/dose_reminder_texts.dart';
import 'package:app/core/services/reminders/dose_snoozer.dart';
import 'package:app/core/services/reminders/reminder_permission.dart';
import 'package:app/core/services/reminders/reminder_sources.dart';
import 'package:app/core/services/reminders/reminder_sync.dart';
import 'package:app/core/services/reminders/reminders_enabled.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/services/reminders/snooze_ledger.dart';
import 'package:app/core/services/reminders/snooze_putter.dart';

/// What [DoseReminders] is made of, wired together: the reading and setting
/// of the reminders ([sync]), the phone's permission, and the tasks put off.
class ReminderParts {
  ReminderParts({
    required ReminderSources sources,
    required PhoneNotifications phone,
    required DoseReminderTexts texts,
    required RemindersEnabled enabled,
    required DateTime Function() now,
    Future<void> Function(SnoozeShare snooze)? share,
  }) {
    final SnoozeLedger ledger = SnoozeLedger(now);
    permission = ReminderPermission(phone);
    sync = ReminderSync(
      sources: sources,
      phone: phone,
      permission: permission,
      ledger: ledger,
      enabled: enabled,
      texts: texts,
    );
    snoozer = DoseSnoozer(
      putter: SnoozePutter(
        ledger: ledger,
        phone: phone,
        permission: permission,
        share: share,
      ),
      texts: texts,
      circles: () => sync.circles,
      now: now,
    );
  }

  late final ReminderPermission permission;
  late final ReminderSync sync;
  late final DoseSnoozer snoozer;
}
