import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_outcome.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_outcome_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The badge of [value] pressed: the menu of [choices] from [anchor],
/// [open] hiding the badge meanwhile, then the one picked kept and said.
/// Nothing to confirm: another choice from the same badge undoes it. A
/// visit whose «ورقة الزيارة» has something in it stays «حضرت», and says
/// why: what was written belongs to a visit that happened.
Future<void> chooseAppointmentOutcome(
  BuildContext context, {
  required BuildContext? anchor,
  required String circleId,
  required CareAppointment value,
  required List<AppointmentOutcome> choices,
  required AppointmentOutcome? current,
  required Widget badge,
  required ValueChanged<bool> open,
}) async {
  if (value.outcomeLocked) {
    AppToast.show(
      context,
      'appointments.outcome_locked',
      kind: ToastKind.error,
    );
  }
  if (value.outcomeLocked || anchor == null) return;
  open(true);
  final AppointmentOutcome? picked = await pickAppointmentOutcome(
    anchor,
    choices: choices,
    current: current,
    badge: badge,
  );
  open(false);
  if (!context.mounted || picked == null || picked == current) return;
  final String? errorKey = await context
      .read<AppointmentsCubit>()
      .changeOutcome(circleId, value, picked);
  if (!context.mounted) return;
  AppToast.show(
    context,
    errorKey ?? 'toast.appointment_outcome',
    kind: errorKey == null ? ToastKind.success : ToastKind.error,
  );
}
