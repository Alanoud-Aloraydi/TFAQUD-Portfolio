import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/appointment_lead.dart';
import 'package:app/core/services/reminders/dose_reminder_texts.dart';
import 'package:app/core/services/reminders/planned_reminder.dart';
import 'package:app/core/services/reminders/reminder_moments.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/appointments/domain/appointment.dart';

/// Two reminders for each of [appointments] still to come, inside the
/// window ([inWindow]); then the one said right away for a visit saved
/// after its day-before moment.
List<PlannedReminder> plannedAppointments(
  List<(ReminderCircle, CareAppointment)> appointments,
  DoseReminderTexts texts,
  bool Function(DateTime at) inWindow,
) => <PlannedReminder>[
  for (final (ReminderCircle circle, CareAppointment visit) in appointments)
    if (visit.status == AppointmentStatus.scheduled)
      // The day before, fixed; and the near one at the lead chosen
      // when the visit was booked (an hour by default, up to six),
      // which used to be two hours for every visit alike.
      for (final (AppointmentLead lead, Duration before)
          in <(AppointmentLead, Duration)>[
            (AppointmentLead.dayBefore, const Duration(days: 1)),
            (AppointmentLead.soon, visit.reminderLead),
          ])
        if (inWindow(
          circle.clock.momentOf(visit.scheduledOn, visit.time).subtract(before),
        ))
          PlannedReminder(
            at: circle.clock
                .momentOf(visit.scheduledOn, visit.time)
                .subtract(before),
            circle: circle,
            title: texts.appointmentTitle(circle, lead, visit),
            body: texts.appointmentBody(visit),
            prefix: appointmentReminderPayload,
            appointmentId: visit.id,
          ),
  // Saved for today or tomorrow after its day-before moment: said once,
  // right away, so a change made today is not silent until the visit's
  // own reminder.
  for (final (ReminderCircle circle, CareAppointment visit) in appointments)
    if (visit.status == AppointmentStatus.scheduled)
      if (appointmentAnnouncedAt(circle.clock, visit) case final DateTime at
          when inWindow(at))
        PlannedReminder(
          at: at,
          circle: circle,
          // «اليوم», or «غدًا» for a visit the next day.
          title: texts.appointmentTitle(
            circle,
            announcedLead(circle.clock, visit, at),
            visit,
          ),
          body: texts.appointmentBody(visit),
          prefix: appointmentReminderPayload,
          appointmentId: visit.id,
        ),
];
