import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

// The words of an appointment, shared by the appointments, home («اليوم»,
// the exported record) and simplified-mode features.

/// The card title: «عيادة» plus a preset specialty, or the typed name.
String appointmentTitle(BuildContext context, CareAppointment value) {
  const presets = {
    'internal',
    'diabetes',
    'cardiology',
    'eyes',
    'dental',
    'neurology',
  };
  if (!presets.contains(value.specialty)) return value.specialty;
  return '${context.tr('appointments.clinic')} '
      '${context.tr('appointments.specialties.${value.specialty}')}';
}

/// The kind of visit; a typed kind when the kind is «غيره».
String appointmentKindTitle(BuildContext context, CareAppointment value) =>
    value.kind == AppointmentKind.other
    ? value.otherKind ?? context.tr('appointments.kinds.other')
    : context.tr('appointments.kinds.${value.kind.name}');

/// The companions' names, joined with «،»; «بدون مرافق» for a visit
/// nobody goes to with the patient (going is optional).
String appointmentCompanionNames(BuildContext context, CareAppointment value) =>
    value.companions.isEmpty
    ? context.tr('appointments.no_companion')
    : value.companions
          .map((companion) => companion.name)
          .join(context.tr('appointments.companion_separator'));

/// «المرافقون: لين، حامد», or «بدون مرافق».
String appointmentCompanionLine(BuildContext context, CareAppointment value) =>
    value.companions.isEmpty
    ? context.tr('appointments.no_companion')
    : context.tr(
        'appointments.companion_name',
        args: [appointmentCompanionNames(context, value)],
      );

/// «الأحد 3 نوفمبر»: the weekday, day and month of [date].
String appointmentDate(BuildContext context, DateTime date) =>
    '${context.tr('common.weekdays.${date.weekday}')} '
    '${date.day} ${context.tr('circles.months.${date.month}')}';
