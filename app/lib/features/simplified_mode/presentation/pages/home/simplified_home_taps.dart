import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/presentation/controllers/reminder_taps.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The reminder taps of the home opened from [context]: they open the
/// full-screen reminder once the day is read.
ReminderTaps simplifiedHomeTaps(BuildContext context) {
  return ReminderTaps(
    phone: GetIt.I<PhoneNotifications>(),
    hasDay: () => context.read<SimplifiedModeCubit>().state.day != null,
    snooze: (String tap) =>
        context.read<SimplifiedModeCubit>().snoozeFromNotification(tap),
    open: (ReminderRequest request) =>
        unawaited(context.push(Routes.simplifiedReminder, extra: request)),
  );
}
