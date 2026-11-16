import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the full-screen reminder of that exact [task], the same screen a
/// tapped notification opens, for a dose, a reading or a visit alike: its
/// picture, and its own answer («أخذته», «تسجيل القياس الآن», «حضرت»).
void openSimplifiedTask(BuildContext context, TodayTask task, String circleId) {
  unawaited(
    context.push(
      Routes.simplifiedReminder,
      extra: ReminderRequest.of(task, circleId),
    ),
  );
}
