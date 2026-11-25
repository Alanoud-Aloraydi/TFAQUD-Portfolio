import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The card title: the kind, or the typed kind for «أخرى».
String appointmentTitle(BuildContext context, CareAppointment value) =>
    value.kind == AppointmentKind.other
    ? value.otherKind ?? context.tr('appointments.kinds.other')
    : context.tr('appointments.kinds.${value.kind.name}');

/// The clinic or doctor as typed, or null when none was given.
String? appointmentClinic(CareAppointment value) {
  final String? clinic = value.specialty?.trim();
  return clinic == null || clinic.isEmpty ? null : clinic;
}

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

/// «الأحد 3 نوفمبر», or «الأحد 12 جمادى الآخرة» in Hijri: the weekday,
/// day and month of [date].
String appointmentDate(BuildContext context, DateTime date) =>
    '${context.tr('common.weekdays.${date.weekday}')} '
    '${calendarDate(context, date, year: false)}';

/// «مراجعة، عيادة السكري»: the visit's kind, then the clinic or doctor
/// when one was typed. For notifications and the calendar, with no context.
String visitName(CareAppointment visit) {
  final String kind = visit.kind == AppointmentKind.other
      ? visit.otherKind ?? 'appointments.kinds.other'.tr()
      : 'appointments.kinds.${visit.kind.name}'.tr();
  final String? clinic = appointmentClinic(visit);
  return clinic == null ? kind : '$kind، $clinic';
}
