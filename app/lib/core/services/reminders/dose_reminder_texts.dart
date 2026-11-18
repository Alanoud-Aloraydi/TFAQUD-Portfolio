import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/appointment_lead.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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

  /// «يا ياسر، لا ننسى ميتفورمين» over the dose, «1 حبة، الساعة 9:00 م».
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

  /// «الساعة 4:30 م، مستشفى الملك فهد».
  final String Function(CareAppointment appointment) appointmentBody;

  /// The last note: open the app so the reminders go on.
  final String Function() keepTitle;
  final String Function() keepBody;
}
