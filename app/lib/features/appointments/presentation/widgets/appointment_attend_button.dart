import 'dart:async';

import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/task_viewer_scope.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «حضرت» under an appointment of «اليوم»: marks the visit attended, then
/// opens its «ورقة الزيارة» to fill in; «السجل» can change it later.
class AppointmentAttendButton extends StatelessWidget {
  const AppointmentAttendButton({
    super.key,
    required this.value,
    required this.circleId,
  });

  final CareAppointment value;
  final String circleId;

  /// «حضرت» for a row at [now] (the patient's wall clock), or nothing: for
  /// a visit still open, from an hour before (as the server allows,
  /// ATTEND_EARLY), and only to those who went — the patient and the
  /// companions chosen for it. Managing appointments is not being at one.
  static Widget? forRow(
    BuildContext context,
    CareAppointment value,
    DateTime now,
    String? circleId,
  ) {
    final DateTime opens = value.scheduledAt.subtract(const Duration(hours: 1));
    if (circleId == null || opens.isAfter(now)) return null;
    if (value.status != AppointmentStatus.scheduled) return null;
    final TaskViewerScope? viewer = TaskViewerScope.of(context);
    if (viewer == null || !viewer.goesWith(value.companionIds)) return null;
    return AppointmentAttendButton(value: value, circleId: circleId);
  }

  @override
  Widget build(BuildContext context) => TaskButtonGrid(
    answer: TaskButton(
      role: TaskButtonRole.answer,
      icon: CupertinoIcons.checkmark,
      label: context.tr('appointments.mark_completed'),
      onPressed: () => _attend(context),
    ),
  );

  Future<void> _attend(BuildContext context) async {
    final String? errorKey = await context.read<AppointmentsCubit>().setStatus(
      circleId,
      value,
      AppointmentStatus.completed,
    );
    if (!context.mounted) return;
    if (errorKey != null) {
      return AppToast.show(context, errorKey, kind: ToastKind.error);
    }
    AppToast.show(context, 'toast.appointment_completed');
    final String visit = Routes.appointmentVisit(circleId, value.id);
    unawaited(context.push<void>('$visit?fill=1', extra: true));
  }
}
