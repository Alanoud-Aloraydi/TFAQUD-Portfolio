import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/presentation/controllers/reminder_taps.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/home/simplified_home_push.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Every state with a day, not only the first: a reminder tapped while
/// the day was still being read waits for one of them.
bool simplifiedHomeListens(
  SimplifiedModeState before,
  SimplifiedModeState after,
) {
  return after.day != null ||
      (after.messageKey != null && after.messageKey != before.messageKey);
}

/// Starts the push and the pending reminder once the day is read, and
/// shows a failure once.
void simplifiedHomeListen(
  BuildContext context,
  SimplifiedModeState state, {
  required SimplifiedHomePush push,
  required ReminderTaps taps,
}) {
  if (state.day case final SimplifiedDay day) {
    push.start(day.accountId);
    taps.openPending();
  }
  final String? key = state.messageKey;
  if (key != null && state.status == SimplifiedModeStatus.ready) {
    AppToast.show(context, key, kind: ToastKind.error);
    context.read<SimplifiedModeCubit>().messageShown();
  }
}
