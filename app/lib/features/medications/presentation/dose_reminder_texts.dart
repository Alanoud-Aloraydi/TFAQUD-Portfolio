import 'package:app/core/l10n/care_voice.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';

/// The Arabic words of the reminders, read when they are set (the
/// translations are loaded by then). A dose: «حان موعد الدواء» over the
/// signed-in person called by name, «يا ياسر، لا ننسى الميلبون». For a
/// circle they care for, the patient's name follows: «يا ياسر، لا ننسى
/// الميلبون لـمحمود». «لا ننسى» (we) is the same for a man and a woman, as
/// «لا تنسى» and «لا تنسي» are not.
final DoseReminderTexts doseReminderTexts = DoseReminderTexts(
  title: (ReminderCircle circle, DoseOccurrence dose) =>
      'reminders.dose_title'.tr(),
  // «يا ياسر، لا ننسى الميلبون».
  body: (ReminderCircle circle, DoseOccurrence dose) =>
      _named('reminders.dose_call', circle, <String>[withArticle(dose.name)]),
  // «ياسر، وقت القياس الحين».
  measurementTitle: (ReminderCircle circle) {
    final String? name = _viewer();
    return name == null
        ? 'reminders.measurement_title'.tr()
        : 'reminders.measurement_title_named'.tr(args: <String>[name]);
  },
  // «سكر الدم», or «سكر الدم لـمحمود» for someone caring for him.
  measurementBody: (ReminderCircle circle, MeasurementOccurrence task) {
    final String kind = switch (task.kind) {
      MeasurementKind.glucose => 'measurements.glucose'.tr(),
      MeasurementKind.bp => 'measurements.bp'.tr(),
    };
    final String? patient = CareVoice.patientOf(circle.id);
    return patient == null
        ? kind
        : 'reminders.measurement_body_for'.tr(args: <String>[kind, patient]);
  },
  // «يا ياسر، لا ننسى موعد محمود بكرة», «يا ياسر، لا ننسى موعدك بعد
  // ساعتين», «… اليوم».
  appointmentTitle:
      (ReminderCircle circle, AppointmentLead lead, CareAppointment visit) =>
          _appointment(switch (lead) {
            AppointmentLead.dayBefore => 'reminders.appointment_tomorrow',
            AppointmentLead.soon => 'reminders.appointment_soon',
            AppointmentLead.today => 'reminders.appointment_today',
          }, circle),
  // «عيادة السكري · الساعة 4:30 م · مستشفى الملك فهد».
  appointmentBody: (CareAppointment visit) {
    final String place = visit.place?.trim() ?? '';
    return place.isEmpty
        ? 'reminders.appointment_body'.tr(
            args: <String>[_clinic(visit), _clock(visit.time)],
          )
        : 'reminders.appointment_body_place'.tr(
            args: <String>[_clinic(visit), _clock(visit.time), place],
          );
  },
  keepTitle: () => 'reminders.keep_title'.tr(),
  keepBody: () => 'reminders.keep_body'.tr(),
);

/// The signed-in person's name, or null.
String? _viewer() {
  final String? name = CareVoice.viewerName?.trim();
  return name == null || name.isEmpty ? null : name;
}

/// [key], `${key}_named` with the viewer's name first, and `_for` with the
/// patient's name last for a circle the viewer cares for.
String _named(String key, ReminderCircle circle, List<String> args) {
  final String? name = _viewer();
  final String? patient = CareVoice.patientOf(circle.id);
  return '$key${name == null ? '' : '_named'}${patient == null ? '' : '_for'}'
      .tr(args: <String>[?name, ...args, ?patient]);
}

/// «يا ياسر، لا ننسى موعدك …», or «… موعد محمود …» for a circle the viewer
/// cares for.
String _appointment(String key, ReminderCircle circle) {
  final String? name = _viewer();
  final String? patient = CareVoice.patientOf(circle.id);
  return '$key${name == null ? '' : '_named'}${patient == null ? '' : '_for'}'
      .tr(args: <String>[?name, ?patient]);
}

/// «عيادة السكري» for a specialty of the list (saved as its code,
/// «diabetes»); one the person wrote, as written.
String _clinic(CareAppointment visit) {
  final String key = 'appointments.specialties.${visit.specialty}';
  if (visit.specialty == 'other' || !key.trExists()) return visit.specialty;
  return '${'appointments.clinic'.tr()} ${key.tr()}';
}

/// [name] with «ال» before it, as Arabic says a known thing: «الأنسولين».
/// A name that has it already («البنادول»), or that is not written in
/// Arabic («Panadol»), stays as it is.
String withArticle(String name) {
  final String value = name.trim();
  if (value.isEmpty || value.startsWith('ال')) return value;
  final int first = value.codeUnitAt(0);
  // The Arabic letters, hamza to yeh.
  final bool arabic = first >= 0x0621 && first <= 0x064A;
  return arabic ? 'ال$value' : value;
}

/// «4:30 م», the same as the appointment pages show it.
String _clock(String time) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final int minute = int.parse(parts[1]);
  return '${hour % 12 == 0 ? 12 : hour % 12}:'
      '${minute.toString().padLeft(2, '0')} '
      '${(hour < 12 ? 'common.am' : 'common.pm').tr()}';
}
