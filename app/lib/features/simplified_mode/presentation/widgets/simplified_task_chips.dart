import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a dose's medicine is for («الكوليسترول»), when the plan says. It
/// is said once, as a chip, never again beside the amount.
String? simplifiedDoseReason(TodayTask task, SimplifiedDay day) =>
    day.reasons[task.dose!.planId] ?? task.dose!.reason;

/// The short notes of a task: a dose's instructions and the medicine's
/// reason, a glucose task's context, an appointment's companions.
List<String> simplifiedTaskChips(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
) {
  return switch (task.kind) {
    TodayTaskKind.medication => <String>[
      if (task.dose!.instructions case final String text
          when text.trim().isNotEmpty)
        text.trim(),
      ?simplifiedDoseReason(task, day),
    ],
    TodayTaskKind.measurement => <String>[
      if (task.measurement!.measurementState case final state?)
        context.tr('measurements.condition.$state'),
    ],
    TodayTaskKind.appointment => <String>[
      if (task.appointment!.companions.isNotEmpty)
        context.tr(
          'simplified_mode.with_companions',
          args: <String>[
            task.appointment!.companions
                .map((companion) => companion.name)
                .join(context.tr('appointments.companion_separator')),
          ],
        ),
    ],
  };
}
