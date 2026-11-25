import 'package:app/app/services/reminders/dose_reminders.dart' show TaskSnooze;
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/widgets/apply_text_scale.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
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

class SimplifiedEmptyCard extends StatelessWidget {
  const SimplifiedEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      child: Text(
        context.tr('simplified_mode.nothing_today'),
        textAlign: TextAlign.center,
        style: SimplifiedStyle.head(SimplifiedStyle.headline),
      ),
    );
  }
}

/// A page or part the simplified mode takes from the detailed mode (the
/// medical file's edit page, the emergency card, the contact form) at the
/// simplified mode's size, on top of [SimplifiedTextScale].
///
/// The mode puts nothing below [SimplifiedStyle.caption], so the smallest
/// type of the borrowed page is what is measured: its footnotes reach that
/// floor, and the rest of its type grows in proportion. Measuring the body
/// instead left the footnotes — the medicine lines of the card, the hints
/// under a field — under the floor, which is the type this mode exists for.
class SimplifiedDetailScale extends StatelessWidget {
  const SimplifiedDetailScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double smallest =
        Theme.of(context).textTheme.bodySmall?.fontSize ??
        SimplifiedStyle.caption;
    return applyTextScale(context, SimplifiedStyle.caption / smallest, child);
  }
}
