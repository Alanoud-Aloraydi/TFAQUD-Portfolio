import 'dart:async';

import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/dose_reminder_texts.dart';
import 'package:app/app/services/reminders/dose_snoozer.dart';
import 'package:app/app/services/reminders/reminder_permission.dart';
import 'package:app/app/services/reminders/reminder_reading.dart';
import 'package:app/app/services/reminders/reminder_sync.dart';
import 'package:app/app/services/reminders/reminders_enabled.dart';
import 'package:app/app/services/reminders/shared_snooze.dart';
import 'package:app/app/services/reminders/snooze_ledger.dart';
import 'package:app/app/services/reminders/snooze_putter.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:app/app/services/reminder_circle.dart';
export 'package:app/app/services/reminders/reminder_payloads.dart';
export 'package:app/app/services/reminders/reminder_plan.dart';
export 'package:app/app/services/reminders/shared_snooze.dart';
export 'package:app/app/services/reminders/task_snooze.dart';

/// Keeps the coming week's reminders on the phone: every dose, measurement
/// and appointment (the name stays from when it reminded of doses only).
/// The phone shows them with the app closed. They are set again when the
/// home data loads ([sync]), when the app comes back ([refresh]), and after
/// any change to a medicine, a record, a plan or an appointment; [clear]
/// removes them on sign-out, as turning them off ([enabled]) does. While
/// the server sends them instead ([server]), none is set here.
///
/// A task put off is told to the circle too (`share`), which reminds the
/// other members: this phone then stays quiet at the planned time.
class DoseReminders with ReminderPermissions, DoseSnoozing {
  DoseReminders(
    MedicationsUseCase medications,
    PhoneNotifications phone, {
    required this.texts,
    MeasurementsUseCase? measurements,
    AppointmentsUseCase? appointments,
    Future<void> Function(SnoozeShare snooze)? share,
    DateTime Function()? clock,
  }) {
    _parts = ReminderParts(
      sources: ReminderSources(
        medications,
        measurements: measurements,
        appointments: appointments,
      ),
      phone: phone,
      texts: texts,
      enabled: enabled,
      now: clock ?? DateTime.now,
      share: share,
    );
    // Kept for the life of the app, as this object is.
    medications.changes.listen((_) => unawaited(refresh()));
    measurements?.changes.listen((_) => unawaited(refresh()));
    measurements?.recorded.listen((_) => unawaited(refresh()));
    appointments?.changes.listen((_) => unawaited(refresh()));
    enabled.on.addListener(() => unawaited(refresh()));
    unawaited(enabled.read());
  }

  /// The words of the reminders.
  final DoseReminderTexts texts;

  late final ReminderParts _parts;

  @override
  ReminderPermission get permission => _parts.permission;

  @override
  DoseSnoozer get snoozer => _parts.snoozer;

  /// Whether the person still wants the reminders; see [RemindersEnabled].
  /// A change plans them again, or takes them all off.
  final RemindersEnabled enabled = RemindersEnabled();

  /// Whether the server sends the reminders instead; see [ServerReminders].
  ServerReminders get server => _parts.server;

  /// Reminds of the doses of [circles] from now on. Called when the home
  /// data loads with the person's circles.
  Future<void> sync(List<ReminderCircle> circles) => _parts.sync.sync(circles);

  /// Reads the doses again and sets the reminders. One reading runs at a
  /// time; a call during it makes one more reading right after.
  Future<void> refresh() => _parts.sync.refresh();

  /// Removes every reminder: the person signed out, or the sign-in ended;
  /// the next sign-in asks the server again whether it sends them.
  Future<void> clear() => _parts.clear();
}

/// What [DoseReminders] is made of, wired together: the reading and setting
/// of the reminders ([sync]), the phone's permission, the tasks put off, and
/// whether the server sends the reminders instead ([server]).
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
      fromServer: () => server.on.value,
    );
    snoozer = DoseSnoozer(
      putter: SnoozePutter(
        ledger: ledger,
        phone: phone,
        permission: permission,
        enabled: enabled,
        share: share,
      ),
      texts: texts,
      circles: () => sync.circles,
      now: now,
    );
    // Planned again when the server starts or stops sending them.
    server.on.addListener(() => unawaited(sync.refresh()));
    unawaited(server.read());
  }

  final ServerReminders server = ServerReminders();
  late final ReminderPermission permission;
  late final ReminderSync sync;
  late final DoseSnoozer snoozer;

  /// [ReminderSync.clear]; the server is asked again at the next sign-in.
  Future<void> clear() async {
    await sync.clear();
    await server.set(false);
  }
}

/// What the phone allows the reminders to do, as [DoseReminders] gives it.
mixin ReminderPermissions {
  @protected
  ReminderPermission get permission;

  /// What the phone allows the reminders to do; see [ReminderPermission].
  ValueListenable<AppPermission?> get allowed => permission.value;

  /// The phone's answer as it stands, without asking for it.
  Future<AppPermission> refreshPermission() => permission.read();

  /// Puts the phone's own question, which iOS shows only the first time.
  Future<AppPermission> requestPermission() => permission.ask(request: true);
}

/// Whether the server sends this phone the reminders at the tasks' times,
/// as its answer to the phone's push subscription last said (backend
/// `app/push/scheduled/reminders`).
///
/// While it does, the phone sets none of its own, so nobody is reminded
/// twice. The server reads the plan at each reminder's moment, so a change
/// someone else made reaches this phone even when the app was not opened.
/// A task put off from this phone still comes again from the phone itself.
///
/// Kept on the phone, so an app opened without a network goes on as the
/// server last said. Off until the server says so: a server from before,
/// or one with its switch off, leaves the reminders to the phone.
class ServerReminders {
  static const String _key = 'server_reminders';

  /// Off until [read] or the server says otherwise.
  final ValueNotifier<bool> on = ValueNotifier<bool>(false);

  /// Whether the server answered since the app started: its answer wins
  /// over the one [read] finds kept.
  bool _answered = false;

  Future<void> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!_answered) on.value = prefs.getBool(_key) ?? false;
  }

  /// Keeps the server's answer; a change plans the reminders again.
  Future<void> set(bool value) async {
    _answered = true;
    on.value = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Whether the server's [answer] to the phone's push subscription says it
/// sends this phone the reminders. A server from before answers nothing.
bool serverRemindsFrom(Object? answer) =>
    answer is Map && answer['server_reminders'] == true;
