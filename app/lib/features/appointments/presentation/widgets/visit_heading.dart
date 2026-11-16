import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The first block of the visit page: what the appointment was, when it
/// was, and where it was with whom.
Widget visitHeading(BuildContext context, CareAppointment appointment) {
  final String day = appointmentDate(context, appointment.scheduledOn);
  final String clock = clockText(appointment.time);
  final String place = appointment.kind == AppointmentKind.remote
      ? context.tr('appointments.${appointment.remoteMethod}')
      : appointment.place ?? '';
  final String companions = appointmentCompanionLine(context, appointment);
  return MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appointmentTitle(context, appointment),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '$day، $clock',
          style: Theme.of(context).textTheme.bodyMedium,
          semanticsLabel: spoken('$day، $clock'),
        ),
        Text(
          '$place، $companions',
          style: Theme.of(context).textTheme.bodySmall,
          semanticsLabel: spoken('$place، $companions'),
        ),
      ],
    ),
  );
}
