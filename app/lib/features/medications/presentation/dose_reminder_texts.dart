import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';

/// The Arabic words of the reminders, read when they are set (the
/// translations are loaded by then).
final DoseReminderTexts doseReminderTexts = DoseReminderTexts(
  // «تذكير لطيف: حان موعد دواء أمي نورة».
  title: (ReminderCircle circle) =>
      'reminders.dose_title'.tr(args: <String>[circle.name]),
  // Only the medicine's name, «ميتفورمين»: the dose is on the Today page.
  body: (DoseOccurrence dose) => dose.name,
  // «تذكير لطيف: حان وقت قياس أمي نورة».
  measurementTitle: (ReminderCircle circle) =>
      'reminders.measurement_title'.tr(args: <String>[circle.name]),
  // «سكر الدم» or «ضغط الدم».
  measurementBody: (MeasurementOccurrence task) => switch (task.kind) {
    MeasurementKind.glucose => 'measurements.glucose'.tr(),
    MeasurementKind.bp => 'measurements.bp'.tr(),
  },
  // «تذكير لطيف: موعد أمي نورة بكرة» / «… بعد ساعتين».
  appointmentTitle: (ReminderCircle circle, AppointmentLead lead) =>
      (switch (lead) {
        AppointmentLead.dayBefore => 'reminders.appointment_tomorrow_title',
        AppointmentLead.soon => 'reminders.appointment_soon_title',
      }).tr(args: <String>[circle.name]),
  // «موعد القلب الساعة 4:30 م».
  appointmentBody: (CareAppointment visit) => 'reminders.appointment_body'.tr(
    args: <String>[visit.specialty, _clock(visit.time)],
  ),
  keepTitle: () => 'reminders.keep_title'.tr(),
  keepBody: () => 'reminders.keep_body'.tr(),
);

/// «4:30 م», the same as the appointment pages show it.
String _clock(String time) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final int minute = int.parse(parts[1]);
  return '${hour % 12 == 0 ? 12 : hour % 12}:'
      '${minute.toString().padLeft(2, '0')} '
      '${(hour < 12 ? 'common.am' : 'common.pm').tr()}';
}
