import 'package:app/core/services/reminders/dose_reminders.dart'
    show TaskSnooze;
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_empty_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_card.dart';
import 'package:flutter/material.dart';

/// The one card «اليوم» leads with: a late dose, the next task, or that
/// everything is done or there is nothing today.
class SimplifiedHomeFocus extends StatelessWidget {
  const SimplifiedHomeFocus({
    super.key,
    required this.day,
    required this.schedule,
    required this.now,
    required this.snoozes,
  });

  final SimplifiedDay day;
  final TodaySchedule schedule;
  final DateTime now;

  /// The tasks put off with «ذكّرني لاحقًا», by [TodayTaskSnoozeKey.snoozeKey].
  final Map<String, TaskSnooze> snoozes;

  @override
  Widget build(BuildContext context) {
    return switch (schedule.focus) {
      HomeFocus.lateDose => SimplifiedLateDoseCard(
        task: schedule.focusTask!,
        day: day,
        snoozed: simplifiedSnoozed(
          context,
          snoozes,
          day.circleId,
          schedule.focusTask!,
        ),
      ),
      HomeFocus.task => SimplifiedNextCard(
        task: schedule.focusTask!,
        day: day,
        schedule: schedule,
        now: now,
        snoozed: simplifiedSnoozed(
          context,
          snoozes,
          day.circleId,
          schedule.focusTask!,
        ),
      ),
      HomeFocus.allDone => SimplifiedDoneCard(schedule: schedule),
      HomeFocus.empty => const SimplifiedEmptyCard(),
    };
  }
}
