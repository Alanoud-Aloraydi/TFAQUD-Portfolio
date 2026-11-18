import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
