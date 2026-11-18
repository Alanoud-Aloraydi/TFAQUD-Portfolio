import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «أضاف الموعد» in an appointment's details: the one person who added it;
/// null when the server does not say who.
Widget? appointmentAddedByGroup(
  BuildContext context,
  CareAppointment value,
  String circleId,
) {
  if (value.createdByName case final String name) {
    return PlanFactGroup(
      title: context.tr('appointments.added_by'),
      children: <Widget>[
        PlanPersonFact(
          name: name,
          circleId: circleId,
          accountId: value.createdBy?.id,
          avatarCode: value.createdBy?.avatarCode,
        ),
      ],
    );
  }
  return null;
}
