part of 'package:app/app/services/calendar_sync.dart';

/// The words of the calendar's events, in the voice of the reminders: «لا
/// ننسى الأنسولين لـنورة», «وقت القياس: سكر الدم», «لا ننسى موعدك: عيادة
/// السكري». Without the «يا ياسر،» of a notification, so the medicine's or
/// clinic's name is what a small calendar box shows first.
class CalendarEventTexts {
  const CalendarEventTexts({
    required this.dose,
    required this.doseNote,
    required this.measurement,
    required this.appointment,
    required this.appointmentNote,
  });

  /// A dose of [medicine] in [circleId].
  final String Function(String circleId, String medicine) dose;

  /// The line inside a dose's event: «حان موعد الدواء».
  final String Function() doseNote;

  /// A reading of [kind] in [circleId].
  final String Function(String circleId, MeasurementKind kind) measurement;

  /// [visit] in [circleId].
  final String Function(String circleId, CareAppointment visit) appointment;

  /// The line inside an appointment's event, the same as its notification:
  /// «عيادة السكري، الساعة 4:30 م، مستشفى الملك فهد».
  final String Function(CareAppointment visit) appointmentNote;
}
