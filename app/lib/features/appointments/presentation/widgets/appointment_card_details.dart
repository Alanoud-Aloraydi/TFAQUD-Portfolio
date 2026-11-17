import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What an appointment card opens, in the groups of a plan's details:
/// «الموعد» (when, where or how, and that it shows in «اليوم» when
/// [appearsToday]), [otherVisits] of its booking, «المرافقون», «أضاف
/// الموعد» (the one person who added it), then for a manager «حضرت» while
/// it can be answered ([AppointmentAttendWindow]) and «إلغاء الموعد» last,
/// the stop button of a medicine. A missed visit asks nothing.
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
  final bool remote = value.kind == AppointmentKind.remote;
  const Size tall = Size(0, AppItemCard.touch);
  return <Widget>[
    PlanFactGroup(
      title: context.tr('appointments.appointment_group'),
      children: <Widget>[
        PlanFact(
          icon: AppIcons.calendar,
          label: context.tr('appointments.date'),
          value:
              '${appointmentDate(context, value.scheduledOn)}، '
              '${clockText(value.time)}',
        ),
        if (remote && value.remoteMethod != null)
          PlanFact(
            icon: AppIcons.phone,
            label: context.tr('appointments.remote_method'),
            value: context.tr('appointments.${value.remoteMethod}'),
          )
        else if (value.place case final String place when place.isNotEmpty)
          PlanFact(
            icon: AppIcons.mapPin,
            label: context.tr('appointments.place'),
            value: place,
          ),
        if (appearsToday)
          PlanFact(
            icon: AppIcons.info,
            value: context.tr('appointments.appears_today'),
          ),
      ],
    ),
    ?otherVisits,
    PlanFactGroup(
      title: context.tr('appointments.companion'),
      children: <Widget>[
        if (value.companions.isEmpty)
          PlanFact(
            icon: AppIcons.users,
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
    ),
    if (value.createdByName case final String name)
      PlanFactGroup(
        title: context.tr('appointments.added_by'),
        children: <Widget>[
          PlanPersonFact(
            name: name,
            circleId: circleId,
            accountId: value.createdBy?.id,
            avatarCode: value.createdBy?.avatarCode,
          ),
        ],
      ),
    if (canManage && value.canAttendAt(clock.now(), clock.today()))
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          style: TextButton.styleFrom(minimumSize: tall),
          onPressed: () => changeAppointmentStatus(
            context,
            circleId,
            value,
            AppointmentStatus.completed,
          ),
          child: Text(context.tr('appointments.mark_completed')),
        ),
      ),
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
