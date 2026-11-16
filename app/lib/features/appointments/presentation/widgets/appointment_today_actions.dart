import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/core/widgets/task_viewer_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_attend_button.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// What an appointment of «اليوم» asks, in the buttons every task shares:
/// «حضرت» across the card, then «تعديل الموعد» and «إلغاء الموعد» under
/// it, so a visit answers the way a dose and a reading do.
///
/// Open from an hour before its time (as the server allows, ATTEND_EARLY)
/// to those who went — the patient and the companions chosen for it — and
/// to those who manage the circle's appointments, who must be able to put
/// the record right. Changing or cancelling the visit is a manager's
/// errand, so a companion who manages nothing only answers «حضرت».
Widget? appointmentTodayActions(
  BuildContext context, {
  required CareAppointment value,
  required DateTime now,
  required String? circleId,
  required bool canManage,
}) {
  final DateTime opens = value.scheduledAt.subtract(const Duration(hours: 1));
  if (circleId == null || opens.isAfter(now)) return null;
  if (value.status != AppointmentStatus.scheduled) return null;
  final bool went =
      TaskViewerScope.of(context)?.goesWith(value.companionIds) ?? false;
  if (!went && !canManage) return null;
  return TaskButtonGrid(
    answer: AppointmentAttendButton(value: value, circleId: circleId),
    choices: <Widget>[
      if (canManage) ...<Widget>[
        TaskButton(
          role: TaskButtonRole.later,
          icon: AppIcons.pencil,
          label: context.tr('appointments.edit'),
          onPressed: () =>
              context.push<bool>(Routes.editAppointment(circleId, value.id)),
        ),
        TaskButton(
          role: TaskButtonRole.skip,
          icon: CupertinoIcons.xmark_circle,
          label: context.tr('appointments.cancel_appointment'),
          onPressed: () => changeAppointmentStatus(
            context,
            circleId,
            value,
            AppointmentStatus.cancelled,
          ),
        ),
      ],
    ],
  );
}
