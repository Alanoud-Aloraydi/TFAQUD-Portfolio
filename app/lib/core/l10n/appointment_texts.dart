import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

// The words of an appointment, shared by the appointments, home («اليوم»,
// the exported record) and simplified-mode features.

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

/// «الأحد 3 نوفمبر»: the weekday, day and month of [date].
String appointmentDate(BuildContext context, DateTime date) =>
    '${context.tr('common.weekdays.${date.weekday}')} '
    '${date.day} ${context.tr('circles.months.${date.month}')}';
