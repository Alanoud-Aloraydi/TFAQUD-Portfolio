import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks to confirm, then marks [value] completed or cancelled and says how
/// it went. [context] must stay mounted while the answer is awaited.
Future<void> changeAppointmentStatus(
  BuildContext context,
  String circleId,
  CareAppointment value,
  AppointmentStatus status,
) async {
  final bool completing = status == AppointmentStatus.completed;
  final bool? confirmed = await showAppAlert<bool>(
    context,
    title: context.tr(
      completing
          ? 'appointments.confirm_completed'
          : 'appointments.confirm_cancelled',
    ),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('appointments.confirm'),
        value: true,
        primary: completing,
        destructive: !completing,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  final String? errorKey = await context.read<AppointmentsCubit>().setStatus(
    circleId,
    value,
    status,
  );
  if (!context.mounted) return;
  if (errorKey != null) {
    AppToast.show(context, errorKey, kind: ToastKind.error);
    return;
  }
  AppToast.show(
    context,
    completing ? 'toast.appointment_completed' : 'toast.appointment_canceled',
  );
}
