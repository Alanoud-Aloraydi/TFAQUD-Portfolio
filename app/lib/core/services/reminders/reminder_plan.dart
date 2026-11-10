/// Which reminders the phone gets: a pure plan of the doses, measurements
/// and appointments to come ([planDoseReminders]), with the phone's limits
/// and the words given from outside ([DoseReminderTexts]). [DoseReminders]
/// reads the server and sets this plan on the phone.
library;

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// Which of an appointment's reminders: the day before, shortly before it,
/// or right after it was saved for today or tomorrow, when the day-before
/// moment had already passed.
enum AppointmentLead { dayBefore, soon, today }

/// The words of the reminders. They are given from outside, so this file
/// needs no translations and the tests can use plain words.
class DoseReminderTexts {
  const DoseReminderTexts({
    required this.title,
    required this.body,
    required this.measurementTitle,
    required this.measurementBody,
    required this.appointmentTitle,
    required this.appointmentBody,
    required this.keepTitle,
    required this.keepBody,
  });

  /// «حان موعد الدواء».
  final String Function(ReminderCircle circle, DoseOccurrence dose) title;

  /// «يا ياسر، لا ننسى ميتفورمين» over the dose, «1 حبة · الساعة 9:00 م».
  final String Function(ReminderCircle circle, DoseOccurrence dose) body;

  /// «ياسر، وقت القياس الحين».
  final String Function(ReminderCircle circle) measurementTitle;

  /// What to measure, «سكر الدم».
  final String Function(
    ReminderCircle circle,
    MeasurementOccurrence measurement,
  )
  measurementBody;

  /// «ياسر! عندك موعد القلب بكرة», or «… بعد ساعتين».
  final String Function(
    ReminderCircle circle,
    AppointmentLead lead,
    CareAppointment appointment,
  )
  appointmentTitle;

  /// «الساعة 4:30 م · مستشفى الملك فهد».
  final String Function(CareAppointment appointment) appointmentBody;

  /// The last note: open the app so the reminders go on.
  final String Function() keepTitle;
  final String Function() keepBody;
}

/// iOS keeps at most 64 scheduled notifications for an app (the 64 set
/// last). The reminders of doses, measurements and appointments share
/// [maxDoseReminders] of them, the nearest first; the note after them takes
/// one more. A dose or measurement put off takes the place of one of the
/// reminders (`maxCardSnoozes`).
const int maxDoseReminders = 60;

/// The ids of the reminders: [reminderIdBase] to [reminderIdBase] + 60.
const int reminderIdBase = 7000;

/// How long before an appointment its second reminder comes; the first
/// comes a day before.
const Duration appointmentSoonLead = Duration(hours: 2);

/// A reminder this close is not set: by the time the phone has it, its
/// moment may have passed. Short, so a medicine saved a minute before its
/// dose is still reminded.
const Duration reminderMargin = Duration(seconds: 10);

/// How long after an appointment is saved its «اليوم» reminder comes, when
/// it was saved after its day-before moment: right away, with time for the
/// phone to set it.
const Duration appointmentSavedLead = Duration(seconds: 30);

/// When an appointment saved after its day-before moment is said right
/// away ([AppointmentLead.today]): [appointmentSavedLead] after it was
/// saved, once (a later refresh finds that moment gone). Null when it was
/// saved earlier, or when its two-hour reminder comes within ten minutes
/// anyway. [clock] is the patient's, whose wall clock the visit's time is.
DateTime? appointmentAnnouncedAt(PatientClock clock, CareAppointment visit) {
  final DateTime moment = clock.momentOf(visit.scheduledOn, visit.time);
  final DateTime saved = visit.updatedAt.toUtc();
  if (!saved.isAfter(moment.subtract(const Duration(days: 1)))) return null;
  final DateTime at = saved.add(appointmentSavedLead);
  final DateTime soon = moment.subtract(appointmentSoonLead);
  final bool soonComes =
      soon.isAfter(at) && soon.difference(at) < const Duration(minutes: 10);
  return at.isBefore(moment) && !soonComes ? at : null;
}

/// The moment a dose is due: its time is the wall clock where the patient
/// lives ([clock]), so it is the same moment on any phone, in any zone.
DateTime doseMoment(PatientClock clock, DoseOccurrence dose) =>
    clock.momentOf(dose.scheduledOn, dose.time);

/// The reminders after [now], the nearest first, at most [limit]:
///
/// * one at each dose not recorded yet (taken or skipped);
/// * one at each measurement not recorded yet;
///
/// (a dose or measurement put off, by its key in [snoozed], has its own
/// reminder at the new time instead);
/// * two for each appointment still to come: a day before it, and
///   [appointmentSoonLead] before it.
///
/// None at or after [until], so the reminders end together and the note
/// after the last one is not far behind the others. After the last one
/// comes a note to open the app, which fires only when the app was not
/// opened in all that time (each opening sets the reminders again, further
/// on).
List<ScheduledNotification> planDoseReminders({
  List<(ReminderCircle, DoseOccurrence)> doses =
      const <(ReminderCircle, DoseOccurrence)>[],
  List<(ReminderCircle, MeasurementOccurrence)> measurements =
      const <(ReminderCircle, MeasurementOccurrence)>[],
  List<(ReminderCircle, CareAppointment)> appointments =
      const <(ReminderCircle, CareAppointment)>[],
  required DateTime now,
  required DoseReminderTexts texts,
  DateTime? until,
  int limit = maxDoseReminders,
  Set<String> snoozed = const <String>{},
}) {
  // A moment in the next few seconds is too close to set: by the time the
  // phone has it, it may have passed.
  final DateTime earliest = now.toUtc().add(reminderMargin);
  bool inWindow(DateTime at) =>
      at.isAfter(earliest) && (until == null || at.isBefore(until));
  final List<_Reminder> upcoming = <_Reminder>[
    for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
      if (dose.record == null &&
          inWindow(doseMoment(circle.clock, dose)) &&
          !snoozed.contains(doseSnoozeKey(circle.id, dose)))
        _Reminder(
          at: doseMoment(circle.clock, dose),
          circle: circle,
          title: texts.title(circle, dose),
          body: texts.body(circle, dose),
          prefix: doseReminderPayload,
          snoozeKey: doseSnoozeKey(circle.id, dose),
          subject: dose.name,
        ),
    for (final (ReminderCircle circle, MeasurementOccurrence task)
        in measurements)
      if (task.record == null &&
          (task.status == MeasurementStatus.upcoming ||
              task.status == MeasurementStatus.due) &&
          inWindow(circle.clock.momentOf(task.scheduledOn, task.time)) &&
          !snoozed.contains(measurementSnoozeKey(circle.id, task)))
        _Reminder(
          at: circle.clock.momentOf(task.scheduledOn, task.time),
          circle: circle,
          title: texts.measurementTitle(circle),
          body: texts.measurementBody(circle, task),
          prefix: measurementReminderPayload,
          snoozeKey: measurementSnoozeKey(circle.id, task),
          subject: task.kind.name,
        ),
    for (final (ReminderCircle circle, CareAppointment visit) in appointments)
      if (visit.status == AppointmentStatus.scheduled)
        for (final (AppointmentLead lead, Duration before)
            in const <(AppointmentLead, Duration)>[
              (AppointmentLead.dayBefore, Duration(days: 1)),
              (AppointmentLead.soon, appointmentSoonLead),
            ])
          if (inWindow(
            circle.clock
                .momentOf(visit.scheduledOn, visit.time)
                .subtract(before),
          ))
            _Reminder(
              at: circle.clock
                  .momentOf(visit.scheduledOn, visit.time)
                  .subtract(before),
              circle: circle,
              title: texts.appointmentTitle(circle, lead, visit),
              body: texts.appointmentBody(visit),
              prefix: appointmentReminderPayload,
            ),
    // Saved for today or tomorrow after its day-before moment: said once,
    // right away, so a change made today is not silent until two hours
    // before.
    for (final (ReminderCircle circle, CareAppointment visit) in appointments)
      if (visit.status == AppointmentStatus.scheduled)
        if (appointmentAnnouncedAt(circle.clock, visit) case final DateTime at
            when inWindow(at))
          _Reminder(
            at: at,
            circle: circle,
            title: texts.appointmentTitle(circle, AppointmentLead.today, visit),
            body: texts.appointmentBody(visit),
            prefix: appointmentReminderPayload,
          ),
  ]..sort((_Reminder a, _Reminder b) => a.at.compareTo(b.at));
  final List<_Reminder> kept = upcoming.take(limit).toList();
  return <ScheduledNotification>[
    for (int i = 0; i < kept.length; i++)
      ScheduledNotification(
        id: reminderIdBase + i,
        at: kept[i].at,
        title: kept[i].title,
        body: kept[i].body,
        // A dose or measurement carries its words and which task it is,
        // for «ذكّرني لاحقًا».
        payload: kept[i].snoozable
            ? payloadWithText(
                '${kept[i].prefix}${kept[i].circle.id}',
                kept[i].title,
                kept[i].body,
                snoozeKey: kept[i].snoozeKey,
                subject: kept[i].subject,
              )
            : '${kept[i].prefix}${kept[i].circle.id}',
        thread: kept[i].circle.id,
        snoozable: kept[i].snoozable,
      ),
    if (kept.isNotEmpty)
      ScheduledNotification(
        id: reminderIdBase + maxDoseReminders,
        at: kept.last.at.add(const Duration(minutes: 1)),
        title: texts.keepTitle(),
        body: texts.keepBody(),
        payload: keepRemindersPayload,
      ),
  ];
}

/// One reminder before it gets its id.
class _Reminder {
  const _Reminder({
    required this.at,
    required this.circle,
    required this.title,
    required this.body,
    required this.prefix,
    this.snoozeKey,
    this.subject,
  });

  final DateTime at;
  final ReminderCircle circle;
  final String title;
  final String body;
  final String prefix;

  /// A dose's or measurement's, which can be put off.
  final String? snoozeKey;
  final String? subject;

  bool get snoozable => snoozeKey != null;
}
