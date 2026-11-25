import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/reminder_taps.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_home_view.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_choice.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_recent_readings.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_skip_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «لماذا لم تأخذها؟»: the patient says a dose was not taken, and why, on
/// one calm dark colour like the reminder it follows. «سبب آخر» lets the
/// patient write the reason, as the detailed mode's note does, and it may
/// stay empty; «رجوع» writes nothing.
class SimplifiedSkipScreen extends StatelessWidget {
  const SimplifiedSkipScreen({super.key, required this.task});

  /// The dose the patient did not take.
  final TodayTask task;

  Future<void> _skip(
    BuildContext context,
    DoseSkipReason reason,
    String? note,
  ) async {
    final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
    final DoseOccurrence dose = task.dose!;
    final bool saved = await cubit.skipDose(dose, reason, note: note);
    if (!saved || !context.mounted) return;
    context.pushReplacement(
      Routes.simplifiedDone,
      extra: SimplifiedDoneMessage.doseSkipped(dose.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (SimplifiedModeCubit cubit) => cubit.state.saving,
    );
    return SimplifiedDarkPage(
      actions: SimplifiedDarkOutlineButton(
        label: context.tr('simplified_mode.back'),
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go(Routes.simplifiedMode),
      ),
      child: SimplifiedSkipBody(
        name: task.dose!.name,
        saving: saving,
        onReason: (DoseSkipReason reason, String? note) =>
            unawaited(_skip(context, reason, note)),
      ),
    );
  }
}

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
