import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reading_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:flutter/material.dart';

/// The next task: the medicine's photo first (how the patient knows it),
/// then the time, the name and what to take.
class SimplifiedNextCard extends StatelessWidget {
  const SimplifiedNextCard({
    super.key,
    required this.task,
    required this.day,
    required this.schedule,
    required this.now,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;
  final TodaySchedule schedule;
  final DateTime now;

  /// «سأذكّرك 2:09 مساءً» when the task is put off.
  final String? snoozed;

  @override
  Widget build(BuildContext context) {
    // The whole card is the one tap, so it is one stop that says everything
    // and carries the action itself: the card inside is excluded.
    final bool recordable = schedule.canRecord(task);
    return Semantics(
      label: spoken(
        simplifiedNextLines(context, task, day, now, snoozed).join('، '),
      ),
      button: recordable,
      onTap: recordable
          ? () => openSimplifiedTask(context, task, day.circleId)
          : null,
      excludeSemantics: true,
      child: _body(context, recordable),
    );
  }

  Widget _body(BuildContext context, bool recordable) {
    return SimplifiedCard(
      padding: EdgeInsets.zero,
      side: const BorderSide(color: SimplifiedColors.ink, width: 2),
      onTap: recordable
          ? () => openSimplifiedTask(context, task, day.circleId)
          : null,
      child: SimplifiedNextContent(
        task: task,
        day: day,
        when: snoozed ?? simplifiedNextWhen(context, task, now),
      ),
    );
  }
}
