import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_details.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_other_visits.dart';
import 'package:flutter/material.dart';

/// What an appointment card opens: its details, with the other dates of its
/// booking. It shows in «اليوم» only for a scheduled visit whose time has not
/// passed, when the card is shown with its relative date.
List<Widget> appointmentCardOpened(
  BuildContext context, {
  required CareAppointment value,
  required String circleId,
  required bool canManage,
  required bool manage,
  required bool showRelativeDate,
  required List<CareAppointment> others,
  required List<CareAppointment> all,
}) {
  return appointmentCardDetails(
    context,
    value: value,
    circleId: circleId,
    canManage: manage,
    appearsToday:
        showRelativeDate &&
        value.status == AppointmentStatus.scheduled &&
        !value.scheduledAt.isBefore(PatientClockScope.of(context).now()),
    otherVisits: appointmentOtherVisits(
      context,
      others: others,
      all: all,
      circleId: circleId,
      canManage: canManage,
    ),
  );
}
