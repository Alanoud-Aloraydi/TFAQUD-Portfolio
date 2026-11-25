import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_details.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_group.dart';
import 'package:easy_localization/easy_localization.dart';
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

/// «المواعيد الأخرى» in a card's details: the other dates of the booking
/// the card shows one of ([others], by date), each with its place in the
/// booking, its day and time, where it stands, and the sheet of one that
/// was attended. [all] are every visit known, for «الزيارة 3 من 4». None
/// when the booking has no other date, so the group is left out.
Widget? appointmentOtherVisits(
  BuildContext context, {
  required List<CareAppointment> others,
  required List<CareAppointment> all,
  required String circleId,
  required bool canManage,
}) {
  if (others.isEmpty) return null;
  return PlanFactGroup(
    title: context.tr('appointments.other_visits'),
    children: <Widget>[
      for (final CareAppointment visit in others)
        PlanFact(
          icon: ScheduleIcons.calendar,
          label: switch (AppointmentSeries.of(visit, all)) {
            final AppointmentSeries at => context.tr(
              'appointments.visit_of_series',
              args: <String>['${at.index}', '${at.count}'],
            ),
            null => null,
          },
          value:
              '${appointmentDate(context, visit.scheduledOn)}، '
              '${clockText(visit.time)}',
          trailing: AppointmentCardStatus(value: visit, relative: false),
          below: visit.status == AppointmentStatus.completed
              ? AppointmentVisitButton(
                  visit: visit,
                  circleId: circleId,
                  canManage: canManage,
                )
              : null,
        ),
    ],
  );
}
