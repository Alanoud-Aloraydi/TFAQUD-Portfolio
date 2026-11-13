import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What an appointment card opens, in the groups of a plan's details:
/// «الموعد» (when, where or how, and that it shows in «اليوم» when
/// [appearsToday]), «المرافقون» with their pictures, «الأشخاص» (who added
/// and last changed it), then the close actions for a manager (the cancel
/// in red, like a stopped medicine).
List<Widget> appointmentCardDetails(
  BuildContext context, {
  required CareAppointment value,
  required String circleId,
  required bool canManage,
  bool appearsToday = false,
}) {
  final bool open = value.status == AppointmentStatus.scheduled;
  final bool remote = value.kind == AppointmentKind.remote;
  final bool passed = !value.scheduledAt.isAfter(
    PatientClockScope.of(context).now(),
  );
  const Size tall = Size(0, AppItemCard.touch);
  return <Widget>[
    PlanFactGroup(
      title: context.tr('appointments.appointment_group'),
      children: <Widget>[
        PlanFact(
          icon: AppIcons.calendar,
          label: context.tr('appointments.date'),
          value:
              '${appointmentDate(context, value.scheduledOn)} · '
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
    if (value.createdByName != null || value.updatedByName != null)
      PlanFactGroup(
        title: context.tr('plan_details.people'),
        children: <Widget>[
          if (value.createdByName case final String name)
            PlanPersonFact(
              label: context.tr('medications.added_by'),
              name: name,
              circleId: circleId,
              accountId: value.createdBy?.id,
              avatarCode: value.createdBy?.avatarCode,
            ),
          if (value.updatedByName case final String name
              when name != value.createdByName)
            PlanPersonFact(
              label: context.tr('medications.last_edited_by'),
              name: name,
              circleId: circleId,
              accountId: value.updatedBy?.id,
              avatarCode: value.updatedBy?.avatarCode,
            ),
        ],
      ),
    if (canManage && open)
      Wrap(
        spacing: AppSpacing.sm,
        children: <Widget>[
          if (passed)
            TextButton(
              style: TextButton.styleFrom(minimumSize: tall),
              onPressed: () => changeAppointmentStatus(
                context,
                circleId,
                value,
                AppointmentStatus.completed,
              ),
              child: Text(context.tr('appointments.mark_completed')),
            ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: tall,
              foregroundColor: AppSemanticColors.statusError,
            ),
            onPressed: () => changeAppointmentStatus(
              context,
              circleId,
              value,
              AppointmentStatus.cancelled,
            ),
            child: Text(context.tr('appointments.cancel_appointment')),
          ),
        ],
      ),
  ];
}
