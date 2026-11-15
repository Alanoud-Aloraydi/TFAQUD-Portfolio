import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/services/reminders/dose_reminders.dart'
    show TaskSnooze;
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_empty_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_link.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_squares.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  /// The tasks put off with «ذكّرني لاحقًا», by [TodayTask.snoozeKey].
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            button: true,
            label: spoken(context.tr('simplified_mode.account_title')),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push(Routes.simplifiedAccount),
              child: PersonPhoto(
                name: day.displayName ?? '',
                photoPath: ApiEndpoints.accountPhoto,
                avatarCode: day.avatarCode,
                size: SimplifiedStyle.touch,
              ),
            ),
          ),
        ),
        const SizedBox(height: SimplifiedStyle.gap),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 12,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  simplifiedGreeting(
                    context,
                    day.displayName,
                    now,
                    day.prayers,
                  ),
                  style: SimplifiedStyle.head(SimplifiedStyle.display),
                ),
                const SizedBox(height: 6),
                Text(
                  simplifiedToday(context, now),
                  style: SimplifiedStyle.text(
                    SimplifiedStyle.body,
                    weight: AppTextTheme.medium,
                  ),
                ),
              ],
            ),
            // The weather where the patient lives, beside the greeting as
            // it is beside the date in «اليوم». It wraps under the
            // greeting when the text is large.
            SimplifiedWeather(latitude: day.latitude, longitude: day.longitude),
          ],
        ),
        const SizedBox(height: SimplifiedStyle.pad),
        switch (schedule.focus) {
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
        },
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
