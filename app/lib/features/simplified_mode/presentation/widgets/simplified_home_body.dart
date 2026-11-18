import 'package:app/core/services/reminders/dose_reminders.dart'
    show TaskSnooze;
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_account_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_focus.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_heading.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_link.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_squares.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

class SimplifiedHomeBody extends StatelessWidget {
  const SimplifiedHomeBody({
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
    return _cards(context);
  }

  Widget _cards(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        8,
        SimplifiedStyle.page,
        28,
      ),
      children: <Widget>[
        SimplifiedHomeAccountButton(day: day),
        const SizedBox(height: SimplifiedStyle.gap),
        SimplifiedHomeHeading(day: day, now: now),
        const SizedBox(height: SimplifiedStyle.pad),
        SimplifiedHomeFocus(
          day: day,
          schedule: schedule,
          now: now,
          snoozes: snoozes,
        ),
        const SizedBox(height: SimplifiedStyle.gap),
        SimplifiedScheduleLink(schedule: schedule),
        if (day.family.isNotEmpty) ...<Widget>[
          const SizedBox(height: SimplifiedStyle.gap),
          SimplifiedFamilyCard(family: day.family, circleId: day.circleId),
        ],
        const SizedBox(height: SimplifiedStyle.gap),
        SimplifiedSquares(circleId: day.circleId),
      ],
    );
  }
}
