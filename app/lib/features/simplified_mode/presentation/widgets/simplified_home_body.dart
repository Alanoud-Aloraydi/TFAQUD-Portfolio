import 'package:app/app/router/routers.dart';
import 'package:app/app/services/reminders/dose_reminders.dart' show TaskSnooze;
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_focus.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_square_content.dart';
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

/// The patient's photo on the corner of «اليوم»: a tap opens their account.
class SimplifiedHomeAccountButton extends StatelessWidget {
  const SimplifiedHomeAccountButton({super.key, required this.day});

  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        label: spoken(context.tr('simplified_mode.account_title')),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push(Routes.simplifiedAccount),
          child: PersonPhoto(
            name: day.displayName ?? '',
            photoPath: AccountEndpoints.accountPhoto,
            avatarCode: day.avatarCode,
            size: SimplifiedStyle.touch,
          ),
        ),
      ),
    );
  }
}

class SimplifiedScheduleLink extends StatelessWidget {
  const SimplifiedScheduleLink({super.key, required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    final List<String> texts = simplifiedScheduleLinkLines(context, schedule);
    return Semantics(
      button: true,
      label: spoken(
        context.tr(
          'simplified_mode.a11y.schedule_link',
          args: <String>[texts[1]],
        ),
      ),
      onTap: () => context.push(Routes.simplifiedSchedule),
      excludeSemantics: true,
      child: _card(context, texts),
    );
  }

  Widget _card(BuildContext context, List<String> texts) {
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 18,
      ),
      onTap: () => context.push(Routes.simplifiedSchedule),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  texts[0],
                  style: SimplifiedStyle.head(SimplifiedStyle.title),
                ),
                Text(
                  texts[1],
                  style: SimplifiedStyle.text(SimplifiedStyle.caption),
                ),
              ],
            ),
          ),
          const Icon(ArrowIcons.next, size: 28, color: SimplifiedColors.ink),
        ],
      ),
    );
  }
}

/// What the schedule link says: its title, then how the day stands.
List<String> simplifiedScheduleLinkLines(
  BuildContext context,
  TodaySchedule schedule,
) => <String>[
  context.tr('simplified_mode.schedule_title'),
  context.tr(
    'simplified_mode.schedule_summary',
    args: <String>['${schedule.doneCount}', '${schedule.total}'],
  ),
];

class SimplifiedSquares extends StatelessWidget {
  const SimplifiedSquares({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SimplifiedSquare(
              dark: true,
              icon: CareVisuals.measurementIcon,
              iconColor: CareVisuals.measurementTile,
              title: context.tr('simplified_mode.record_measurement'),
              subtitle: context.tr('simplified_mode.record_measurement_sub'),
              onTap: () => context.push(Routes.simplifiedMeasure(circleId)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SimplifiedSquare(
              icon: CareIcons.firstAid,
              iconColor: SimplifiedColors.danger,
              title: context.tr('simplified_mode.emergency'),
              subtitle: context.tr('simplified_mode.emergency_sub'),
              onTap: () =>
                  context.push(Routes.simplifiedEmergencyCard(circleId)),
            ),
          ),
        ],
      ),
    );
  }
}

class SimplifiedSquare extends StatelessWidget {
  const SimplifiedSquare({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spoken('$title. $subtitle'),
      // The tap lives on the card inside, which is excluded below, so the
      // node that VoiceOver lands on needs the action of its own.
      onTap: onTap,
      excludeSemantics: true,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return SimplifiedCard(
      color: dark ? SimplifiedColors.ink : SimplifiedColors.surface,
      side: dark
          ? BorderSide.none
          : const BorderSide(color: SimplifiedColors.line),
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: SimplifiedSquareContent(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        dark: dark,
      ),
    );
  }
}
