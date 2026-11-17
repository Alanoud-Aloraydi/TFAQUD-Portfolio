import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/utils/schedule_day.dart';
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

/// What an open visit asks, in the buttons every task shares, wherever it
/// shows on «اليوم» (its row, the top card, «يحتاج انتباهك»): «حضرت»
/// across the card, then «تعديل الموعد» and «إلغاء الموعد» under it.
///
/// On its day those who manage the appointments see «تعديل الموعد» and
/// «إلغاء الموعد». «حضرت» joins them from an hour before its time
/// ([attendEarly], as the server allows), asked only of those who go: the
/// patient and this visit's companions. A manager who does not go is not
/// asked it. Once the visit is missed (two days on) it asks nothing.
Widget? appointmentTodayActions(
  BuildContext context, {
  required CareAppointment value,
  required DateTime now,
  required String? circleId,
  required bool canManage,
}) {
  final DateTime today = scheduleDay(now);
  if (circleId == null || value.status != AppointmentStatus.scheduled) {
    return null;
  }
  if (value.isMissedOn(today)) return null;
  final bool went =
      value.canAttendAt(now, today) &&
      (TaskViewerScope.of(context)?.goesWith(value.companionIds) ?? false);
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
