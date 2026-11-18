import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:flutter/material.dart';

/// What an appointment card calls the visit.
Widget appointmentCardTitle(BuildContext context, CareAppointment value) {
  return Text(
    appointmentTitle(context, value),
    style: Theme.of(context).textTheme.titleMedium,
  );
}

/// The clinic or doctor under the title; null when none was typed.
Widget? appointmentCardClinic(CareAppointment value) {
  return switch (appointmentClinic(value)) {
    final String clinic => Text(clinic),
    null => null,
  };
}

/// The date and time a card starts with.
String appointmentCardStart(BuildContext context, CareAppointment value) {
  return '${appointmentDate(context, value.scheduledOn)}، '
      '${clockText(value.time)}';
}
