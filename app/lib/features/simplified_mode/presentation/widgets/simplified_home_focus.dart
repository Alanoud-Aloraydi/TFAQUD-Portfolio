import 'package:app/app/services/reminders/dose_reminders.dart' show TaskSnooze;
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/apply_text_scale.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reading_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
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

class SimplifiedDoneCard extends StatelessWidget {
  const SimplifiedDoneCard({super.key, required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: spoken(simplifiedDoneLines(context, schedule).join('، ')),
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final (String count, String? tomorrow) = simplifiedDoneCounts(
      context,
      schedule,
    );
    return SimplifiedCard(
      child: Column(
        children: <Widget>[
          const SimplifiedDoneMark(size: 72),
          const SizedBox(height: 12),
          Text(
            context.tr('simplified_mode.all_done'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(26),
          ),
          const SizedBox(height: 6),
          Text(
            tomorrow == null ? count : '$count، $tomorrow',
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the done card says, in its order.
List<String> simplifiedDoneLines(BuildContext context, TodaySchedule schedule) {
  final (String count, String? tomorrow) = simplifiedDoneCounts(
    context,
    schedule,
  );
  return <String>[context.tr('simplified_mode.all_done'), count, ?tomorrow];
}

/// «3 من 3 اليوم», and the first dose of tomorrow when there is one.
(String, String?) simplifiedDoneCounts(
  BuildContext context,
  TodaySchedule schedule,
) => (
  context.tr(
    'simplified_mode.done_count',
    args: <String>['${schedule.doneCount}', '${schedule.total}'],
  ),
  switch (schedule.firstDoseTomorrow) {
    final dose? => context.tr(
      'simplified_mode.first_dose_tomorrow',
      args: <String>[simplifiedTime(context, dose.time)],
    ),
    null => null,
  },
);
