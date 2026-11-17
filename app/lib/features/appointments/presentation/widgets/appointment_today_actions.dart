import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/core/widgets/task_viewer_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_attend_button.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// What an appointment of «اليوم» asks, in the buttons every task shares:
/// «حضرت» across the card, then «تعديل الموعد» and «إلغاء الموعد» under
/// it, so a visit answers the way a dose and a reading do.
///
/// Open from an hour before its time ([attendEarly], as the server allows).
///
/// «حضرت» is asked only of those who went: the patient, and the
/// companions picked for this visit — accompanying belongs to one
/// appointment, not to the circle. Someone who manages the appointments
/// is not thereby at one, so a manager who did not go sees «تعديل
/// الموعد» and «إلغاء الموعد» and is asked nothing; they could not
/// answer for a visit they never attended.
Widget? appointmentTodayActions(
  BuildContext context, {
  required CareAppointment value,
  required DateTime now,
  required String? circleId,
  required bool canManage,
}) {
  if (circleId == null || value.attendOpensAt.isAfter(now)) return null;
  if (value.status != AppointmentStatus.scheduled) return null;
  final bool went =
      TaskViewerScope.of(context)?.goesWith(value.companionIds) ?? false;
  if (!went && !canManage) return null;
  return TaskButtonGrid(
    answer: went
        ? AppointmentAttendButton(value: value, circleId: circleId)
        : null,
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
