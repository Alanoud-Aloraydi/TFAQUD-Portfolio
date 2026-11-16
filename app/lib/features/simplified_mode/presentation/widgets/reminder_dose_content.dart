import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The reminder of a dose: the medicine's photo, what to take, and
/// «أخذته» or «ذكّرني لاحقًا». Null when [task] no longer waits.
SimplifiedReminderContent? reminderDoseContent(
  BuildContext context,
  TodayTask? task,
  SimplifiedDay day, {
  required bool saving,
}) {
  if (task == null) return null;
  final DoseOccurrence dose = task.dose!;
  Future<void> take() async {
    final DateTime? takenAt = await context
        .read<SimplifiedModeCubit>()
        .takeDose(dose);
    if (takenAt == null || !context.mounted) return;
    context.pushReplacement(
      Routes.simplifiedDone,
      extra: SimplifiedDoneMessage.doseTaken(dose.name, takenAt),
    );
  }

  return SimplifiedReminderContent(
    lead: context.tr('simplified_mode.time_for'),
    name: dose.name,
    line:
        '${simplifiedDoseAmount(context, dose)}، '
        '${simplifiedStrength(context, dose)}',
    chips: simplifiedTaskChips(context, task, day),
    hero: (double height) => MedicinePhoto(
      circleId: day.circleId,
      planId: dose.planId,
      height: height,
      radius: 0,
      iconSize: height * .45,
    ),
    yesLabel: context.tr('simplified_mode.took'),
    onYes: saving ? null : () => unawaited(take()),
    onLater: () =>
        context.pushReplacement(Routes.simplifiedSnooze, extra: task),
  );
}
