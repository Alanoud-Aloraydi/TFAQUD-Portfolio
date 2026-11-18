import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/care_item_routes.dart';

/// The pen of an appointment card, opening its form; null when the card
/// cannot be edited, or the visit is no longer scheduled.
EditAction? appointmentCardEdit(
  BuildContext context,
  CareAppointment value,
  String circleId, {
  required bool manage,
}) {
  if (!manage || value.status != AppointmentStatus.scheduled) return null;
  return EditAction.pen(
    onPressed: () =>
        context.push<bool>(CareItemRoutes.editAppointment(circleId, value.id)),
    tooltip: context.tr('appointments.edit'),
  );
}
