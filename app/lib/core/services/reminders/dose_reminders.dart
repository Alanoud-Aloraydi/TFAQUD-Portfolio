import 'dart:async';

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/dose_reminder_texts.dart';
import 'package:app/core/services/reminders/dose_snoozer.dart';
import 'package:app/core/services/reminders/dose_snoozing.dart';
export 'package:app/core/services/reminders/dose_reminders_exports.dart';
import 'package:app/core/services/reminders/reminder_parts.dart';
import 'package:app/core/services/reminders/reminder_permission.dart';
import 'package:app/core/services/reminders/reminder_permissions.dart';
import 'package:app/core/services/reminders/reminder_sources.dart';
import 'package:app/core/services/reminders/reminders_enabled.dart';
import 'package:app/core/services/reminders/server_reminders.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';

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
