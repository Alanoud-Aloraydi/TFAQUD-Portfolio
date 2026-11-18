import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_link_lines.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

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
