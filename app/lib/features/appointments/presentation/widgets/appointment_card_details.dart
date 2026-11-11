import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_detail_line.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What an appointment card opens: who added and last changed it, then the
/// close actions for a manager (the cancel in red, like a stopped medicine).
List<Widget> appointmentCardDetails(
  BuildContext context, {
  required CareAppointment value,
  required String circleId,
  required bool canManage,
}) {
  final bool open = value.status == AppointmentStatus.scheduled;
  final bool passed = !value.scheduledAt.isAfter(
    PatientClockScope.of(context).now(),
  );
  const Size tall = Size(0, AppItemCard.touch);
  return <Widget>[
    if (value.createdByName case final String name)
      PlanDetailLine(context.tr('appointments.added_by', args: <String>[name])),
    if (value.updatedByName case final String name
        when name != value.createdByName)
      PlanDetailLine(
        context.tr('appointments.last_edited_by', args: <String>[name]),
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
