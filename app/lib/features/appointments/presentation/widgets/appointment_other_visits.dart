import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_series.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_visit_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
          icon: AppIcons.calendar,
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
