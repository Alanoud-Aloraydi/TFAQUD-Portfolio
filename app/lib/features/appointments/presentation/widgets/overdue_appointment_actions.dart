import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// «حضرت» and «إلغاء» for an appointment of an earlier day, in the buttons
/// every task shares (TaskButtonRole), each asking to confirm and answering
/// with a toast.
class OverdueAppointmentActions extends StatelessWidget {
  const OverdueAppointmentActions({
    super.key,
    required this.value,
    required this.circleId,
  });

  final CareAppointment value;
  final String circleId;

  @override
  Widget build(BuildContext context) => TaskButtonGrid(
    buttons: <Widget>[
      TaskButton(
        role: TaskButtonRole.answer,
        icon: CupertinoIcons.checkmark,
        label: context.tr('appointments.mark_completed'),
        onPressed: () => _close(context, AppointmentStatus.completed),
      ),
      TaskButton(
        role: TaskButtonRole.skip,
        icon: CupertinoIcons.xmark_circle,
        label: context.tr('appointments.cancel_appointment'),
        onPressed: () => _close(context, AppointmentStatus.cancelled),
      ),
    ],
  );

  Future<void> _close(BuildContext context, AppointmentStatus status) =>
      changeAppointmentStatus(context, circleId, value, status);
}
