import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
