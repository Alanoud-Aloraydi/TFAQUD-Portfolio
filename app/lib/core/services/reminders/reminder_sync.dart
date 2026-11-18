import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/dose_reminder_texts.dart';
import 'package:app/core/services/reminders/plan_reading.dart';
import 'package:app/core/services/reminders/reminder_permission.dart';
import 'package:app/core/services/reminders/reminder_sources.dart';
import 'package:app/core/services/reminders/reminders_enabled.dart';
import 'package:app/core/services/reminders/replace_reminders.dart';
import 'package:app/core/services/reminders/snooze_ledger.dart';
import 'package:app/core/utils/coalescing_runner.dart';

/// Reads the tasks of the circles and sets the planned reminders on the
/// phone, one reading at a time.
class ReminderSync {
  ReminderSync({
    required this.sources,
    required this.phone,
    required this.permission,
    required this.ledger,
    required this.enabled,
    required this.texts,
  });

  final ReminderSources sources;
  final PhoneNotifications phone;
  final ReminderPermission permission;
  final SnoozeLedger ledger;
  final RemindersEnabled enabled;
  final DoseReminderTexts texts;

  /// The circles being reminded of.
  List<ReminderCircle> circles = const <ReminderCircle>[];
  late final CoalescingRunner _runner = CoalescingRunner(_run);
  bool _asked = false;

  /// Goes up at each [clear], so a reading that ends after a sign-out sets
  /// nothing.
  int _session = 0;

  /// Reminds of the doses of [circles] from now on.
  Future<void> sync(List<ReminderCircle> circles) {
    this.circles = List<ReminderCircle>.unmodifiable(circles);
    return refresh();
  }

  /// Reads the doses again and sets the reminders. One reading runs at a
  /// time; a call during it makes one more reading right after.
  Future<void> refresh() => _runner.run();

  /// Removes every reminder: the person signed out, or the sign-in ended.
  Future<void> clear() async {
    _session++;
    circles = const <ReminderCircle>[];
    _runner.dropPending();
    await phone.cancelAll();
    await ledger.drop();
  }

  Future<void> _run() async {
    final int session = _session;
    bool stale() => session != _session;
    if (!enabled.on.value) {
      // Off in the app: nothing more comes, a task put off included.
      await phone.cancelAll();
      return ledger.drop();
    }
    final List<ScheduledNotification>? planned = circles.isEmpty
        ? const <ScheduledNotification>[]
        : await readAndPlan(
            circles: circles,
            sources: sources,
            phone: phone,
            ledger: ledger,
            texts: texts,
            stale: stale,
          );
    if (planned == null) return;
    // The question comes when there is something to remind of, once per run
    // of the app; iOS shows it only the first time.
    if (planned.isNotEmpty) {
      final bool first = !_asked;
      _asked = true;
      await permission.ask(request: first);
      if (stale()) return;
    }
    await replaceReminders(phone, planned, stale);
  }
}
