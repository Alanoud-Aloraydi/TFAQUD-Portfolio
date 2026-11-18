import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_hero.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_lines.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_period_badge.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_text.dart';
import 'package:flutter/material.dart';

/// Inside the next card: the picture with its period on the corner, then
/// the words.
class SimplifiedNextContent extends StatelessWidget {
  const SimplifiedNextContent({
    super.key,
    required this.task,
    required this.day,
    required this.when,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «التالي، بعد ساعتين», or what the task was put off to.
  final String when;

  @override
  Widget build(BuildContext context) {
    final PrayerPeriod? period = simplifiedNextPeriod(task, day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            SimplifiedNextHero(task: task, day: day),
            if (period != null) SimplifiedNextPeriodBadge(period: period),
          ],
        ),
        SimplifiedNextText(task: task, day: day, when: when),
      ],
    );
  }
}
