import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_status_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «حضرت» and «إلغاء» for an appointment of an earlier day, each asking to
/// confirm and answering with a toast.
class OverdueAppointmentActions extends StatelessWidget {
  const OverdueAppointmentActions({
    super.key,
    required this.value,
    required this.circleId,
  });

  final CareAppointment value;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    const Size tall = Size(0, AppItemCard.touch);
    return Wrap(
      spacing: AppSpacing.sm,
      children: <Widget>[
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: tall),
          onPressed: () => _close(context, AppointmentStatus.completed),
          child: Text(context.tr('appointments.mark_completed')),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: tall,
            foregroundColor: AppSemanticColors.statusError,
          ),
          onPressed: () => _close(context, AppointmentStatus.cancelled),
          child: Text(context.tr('appointments.cancel_appointment')),
        ),
      ],
    );
  }

  Future<void> _close(BuildContext context, AppointmentStatus status) =>
      changeAppointmentStatus(context, circleId, value, status);
}
