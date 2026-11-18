import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «المرافقون» in an appointment's details: who goes along, or that nobody
/// does.
Widget appointmentCompanionsFacts(
  BuildContext context,
  CareAppointment value,
  String circleId,
) {
  return PlanFactGroup(
    title: context.tr('appointments.companion'),
    children: <Widget>[
      if (value.companions.isEmpty)
        PlanFact(
          icon: PeopleIcons.users,
          value: context.tr('appointments.no_companion'),
        ),
      for (final AppointmentCompanion companion in value.companions)
        PlanPersonFact(
          label: context.tr('appointments.companion_one'),
          name: companion.name,
          circleId: circleId,
          accountId: companion.id,
          avatarCode: companion.avatarCode,
        ),
    ],
  );
}
