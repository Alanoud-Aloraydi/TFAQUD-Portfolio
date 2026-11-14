import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the full-screen reminder of that exact [task] when it can be
/// recorded now; a measurement goes straight to its reading, which records
/// that task.
void openSimplifiedTask(BuildContext context, TodayTask task, String circleId) {
  if (task.kind == TodayTaskKind.measurement) {
    unawaited(
      context.push(Routes.simplifiedMeasure(circleId), extra: task.measurement),
    );
    return;
  }
  unawaited(
    context.push(
      Routes.simplifiedReminder,
      extra: ReminderRequest.of(task, circleId),
    ),
  );
}
