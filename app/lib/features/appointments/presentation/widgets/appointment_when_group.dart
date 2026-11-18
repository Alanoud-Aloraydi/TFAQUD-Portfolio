import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الموعد» in an appointment's details: when, where or how, and that it
/// shows in «اليوم» when [appearsToday].
Widget appointmentWhenGroup(
  BuildContext context,
  CareAppointment value, {
  required bool appearsToday,
}) {
  final bool remote = value.kind == AppointmentKind.remote;
  return PlanFactGroup(
    title: context.tr('appointments.appointment_group'),
    children: <Widget>[
      PlanFact(
        icon: ScheduleIcons.calendar,
        label: context.tr('appointments.date'),
        value:
            '${appointmentDate(context, value.scheduledOn)}، '
            '${clockText(value.time)}',
      ),
      if (remote && value.remoteMethod != null)
        PlanFact(
          icon: PeopleIcons.phone,
          label: context.tr('appointments.remote_method'),
          value: context.tr('appointments.${value.remoteMethod}'),
        )
      else if (value.place case final String place when place.isNotEmpty)
        PlanFact(
          icon: ScheduleIcons.mapPin,
          label: context.tr('appointments.place'),
          value: place,
        ),
      if (appearsToday)
        PlanFact(
          icon: NoticeIcons.info,
          value: context.tr('appointments.appears_today'),
        ),
    ],
  );
}
