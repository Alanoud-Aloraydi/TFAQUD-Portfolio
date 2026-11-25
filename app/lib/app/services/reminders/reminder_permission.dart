import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminders/appointment_lead.dart';
import 'package:app/app/services/reminders/reminder_limits.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the phone allows the reminders to do, kept in one place so the
/// reminders themselves hold only the asking, never the answer.
///
/// Neither platform tells «not asked yet» from «refused»: Android's
/// `areNotificationsEnabled` and iOS's `checkPermissions` both answer
/// false before the question and after a no. So this remembers whether
/// this install has ever asked, and only calls a false answer a refusal
/// once it has. The difference matters: a refusal is undone in Settings,
/// while a question not yet asked is answered by the app itself.
class ReminderPermission {
  ReminderPermission(this._phone);

  static const String _askedKey = 'reminders.permission.asked';

  final PhoneNotifications _phone;
  final ValueNotifier<AppPermission?> _value = ValueNotifier<AppPermission?>(
    null,
  );

  /// The last answer; null until the first ask or read. Both modes watch
  /// it, so a person whose notifications are off is told instead of
  /// waiting for reminders that cannot arrive.
  ValueListenable<AppPermission?> get value => _value;

  /// The phone's answer as it stands, without asking for it.
  Future<AppPermission> read() => ask(request: false);

  /// Asks the phone, or reads what it already answered, and publishes it.
  Future<AppPermission> ask({required bool request}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (request) {
      await _phone.requestPermission();
      await prefs.setBool(_askedKey, true);
    }
    final AppPermission answer = await _phone.permission();
    // A yes is proof the question was asked, whoever asked it: installs
    // from before this flag existed have none, and would otherwise read
    // as never asked.
    if (answer.usable) await prefs.setBool(_askedKey, true);
    final bool asked = prefs.getBool(_askedKey) ?? false;
    // A no that was never asked for is a question still to come.
    _value.value = answer == AppPermission.denied && !asked
        ? AppPermission.notAsked
        : answer;
    return _value.value!;
  }
}

/// When an appointment saved after its day-before moment is said right
/// away ([AppointmentLead.today]): [appointmentSavedLead] after it was
/// saved, once (a later refresh finds that moment gone). Null when it was
/// saved earlier, or when the visit's own near reminder comes within ten
/// minutes anyway. [clock] is the patient's, whose wall clock the visit's
/// time is.
DateTime? appointmentAnnouncedAt(PatientClock clock, CareAppointment visit) {
  final DateTime moment = clock.momentOf(visit.scheduledOn, visit.time);
  final DateTime saved = visit.updatedAt.toUtc();
  if (!saved.isAfter(moment.subtract(const Duration(days: 1)))) return null;
  final DateTime at = saved.add(appointmentSavedLead);
  final DateTime soon = moment.subtract(visit.reminderLead);
  final bool soonComes =
      soon.isAfter(at) && soon.difference(at) < const Duration(minutes: 10);
  return at.isBefore(moment) && !soonComes ? at : null;
}

/// The words of a visit said right after it was saved, at [at]
/// ([appointmentAnnouncedAt]): «اليوم» for a visit that same day, and
/// «غدًا» ([AppointmentLead.dayBefore]) for one the next day, which a
/// visit saved after its day-before moment can be.
AppointmentLead announcedLead(
  PatientClock clock,
  CareAppointment visit,
  DateTime at,
) => clock.today(at) == scheduleDay(visit.scheduledOn)
    ? AppointmentLead.today
    : AppointmentLead.dayBefore;

/// The moment a dose is due: its time is the wall clock where the patient
/// lives ([clock]), so it is the same moment on any phone, in any zone.
DateTime doseMoment(PatientClock clock, DoseOccurrence dose) =>
    clock.momentOf(dose.scheduledOn, dose.time);
