import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/presentation/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What the next card says, in its order.
List<String> simplifiedNextLines(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
  DateTime now,
  String? snoozed,
) {
  final PrayerPeriod? period = simplifiedNextPeriod(task, day);
  return <String>[
    snoozed ?? simplifiedNextWhen(context, task, now),
    simplifiedTime(context, task.time),
    if (period != null) simplifiedPeriod(context, period),
    simplifiedTaskTitle(context, task),
    // The amount, not the strength. «حبة واحدة» is what the patient
    // acts on; «81 ملغ» is for whoever manages the plan, and spoken it
    // is a whole clause between them and the next thing they need.
    if (task.dose case final dose?) ...<String>[
      simplifiedDoseAmount(context, dose),
    ],
    ...simplifiedTaskChips(context, task, day),
  ];
}

/// The part of the day [task] falls in, or null without today's prayers.
PrayerPeriod? simplifiedNextPeriod(TodayTask task, SimplifiedDay day) =>
    day.prayers == null ? null : prayerPeriodOf(task.time, day.prayers!);

/// «التالي، بعد ساعتين», or «فات موعده» («تأكيد الحضور» for a visit).
String simplifiedNextWhen(BuildContext context, TodayTask task, DateTime now) =>
    task.status == TodayTaskStatus.late
    ? simplifiedLate(context, task)
    : context.tr(
        'simplified_mode.next_in',
        args: <String>[simplifiedUntil(context, task.scheduledAt, now)],
      );
