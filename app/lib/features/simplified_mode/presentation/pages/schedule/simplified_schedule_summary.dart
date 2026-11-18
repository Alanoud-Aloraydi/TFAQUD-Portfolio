import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// How many of the day's tasks are done.
class SimplifiedScheduleSummary extends StatelessWidget {
  const SimplifiedScheduleSummary({super.key, required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(
        'simplified_mode.done_count_short',
        args: <String>['${schedule.doneCount}', '${schedule.total}'],
      ),
      style: SimplifiedStyle.text(
        SimplifiedStyle.caption,
        weight: AppTextTheme.semibold,
      ),
    );
  }
}
