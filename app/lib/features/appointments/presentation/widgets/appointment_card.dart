import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_form_bar.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_group.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_outcome_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One appointment as a plan card, as a medicine's is; a booking of several
/// dates is one card with its [others] in the details. «السجل» is not
/// [editable]: only «ورقة الزيارة» can still be written there, and how the
/// visit went changed from its badge.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.value,
    required this.circleId,
    required this.canManage,
    this.showRelativeDate = false,
    this.editable = true,
    this.others = const <CareAppointment>[],
    this.all = const <CareAppointment>[],
  });

  final CareAppointment value;
  final String circleId;
  final bool canManage;
  final bool showRelativeDate;
  final bool editable;
  final List<CareAppointment> others;
  final List<CareAppointment> all;

  @override
  Widget build(BuildContext context) {
    final bool manage = canManage && editable;
    return PlanItemCard(
      leading: Icon(appointmentKindIcon(value.kind)),
      title: appointmentCardTitle(context, value),
      subtitle: appointmentCardClinic(value),
      edit: appointmentCardEdit(context, value, circleId, manage: manage),
      // In «السجل» a manager changes how it went from its badge.
      status: canManage && !editable
          ? AppointmentOutcomeBadge(value: value, circleId: circleId)
          : AppointmentCardStatus(value: value, relative: showRelativeDate),
      start: appointmentCardStart(context, value),
      body: appointmentCardBody(
        context,
        value: value,
        all: all,
        circleId: circleId,
        canManage: canManage,
      ),
      detailsLabel: context.tr('appointments.details'),
      details: appointmentCardOpened(
        context,
        value: value,
        circleId: circleId,
        canManage: canManage,
        manage: manage,
        showRelativeDate: showRelativeDate,
        others: others,
        all: all,
      ),
    );
  }
}

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
