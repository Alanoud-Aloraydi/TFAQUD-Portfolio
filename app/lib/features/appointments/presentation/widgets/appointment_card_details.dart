import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_form_bar.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_when_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What an appointment card opens, in the groups of a plan's details:
/// «الموعد» (when, where or how, and that it shows in «اليوم» when
/// [appearsToday]), [otherVisits] of its booking, «المرافقون», «أضاف
/// الموعد» (the one person who added it), then for a manager «إلغاء الموعد»
/// last, the stop button of a medicine. «حضرت» is answered in «اليوم»
/// alone, by those who go; a missed visit asks nothing.
List<Widget> appointmentCardDetails(
  BuildContext context, {
  required CareAppointment value,
  required String circleId,
  required bool canManage,
  bool appearsToday = false,
  Widget? otherVisits,
}) {
  final PatientClock clock = PatientClockScope.of(context);
  final bool open =
      value.status == AppointmentStatus.scheduled &&
      !value.isMissedOn(clock.today());
  return <Widget>[
    appointmentWhenGroup(context, value, appearsToday: appearsToday),
    ?otherVisits,
    appointmentCompanionsFacts(context, value, circleId),
    ?appointmentAddedByGroup(context, value, circleId),
    if (canManage && open)
      StopButton(
        label: context.tr('appointments.cancel_appointment'),
        onPressed: () => changeAppointmentStatus(
          context,
          circleId,
          value,
          AppointmentStatus.cancelled,
        ),
      ),
  ];
}

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
