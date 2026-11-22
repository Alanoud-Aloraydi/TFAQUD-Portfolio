import 'package:app/core/services/reminders/appointment_lead.dart';
import 'package:app/core/services/reminders/reminder_limits.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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
