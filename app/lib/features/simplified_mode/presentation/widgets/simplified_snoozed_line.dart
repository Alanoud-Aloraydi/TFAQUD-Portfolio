import 'package:app/app/services/reminders/dose_reminders.dart'
    show SharedSnooze;
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/features/simplified_mode/domain/entities/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The line of a task put off ([text], from [simplifiedSnoozed]). When
/// someone of the family put it off, their photo comes before their name:
/// «التذكير مؤجّل إلى 2:09 مساءً، [photo] لين».
class SimplifiedSnoozedLine extends StatelessWidget {
  const SimplifiedSnoozedLine({
    super.key,
    required this.text,
    required this.task,
    required this.day,
    required this.style,
  });

  final String text;
  final TodayTask task;
  final SimplifiedDay day;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final SharedSnooze? shared = task.dose?.snooze ?? task.measurement?.snooze;
    final String? name = shared?.byName;
    if (shared == null || name == null) return Text(text, style: style);
    final String at = simplifiedClockAt(context, shared.remindAt);
    final String by = context.tr(
      'simplified_mode.snoozed_by',
      args: <String>[at, name],
    );
    // This phone's own snooze, or one without a name, says it in words.
    // The comma of «…، لين» is the photo's place.
    if (text != by) return Text(text, style: style);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        Text(
          context.tr('simplified_mode.snoozed_shared', args: <String>[at]),
          style: style,
        ),
        PersonPhoto(
          name: name,
          photoPath: personPhotoPath(day.circleId, shared.byAccountId),
          avatarCode: shared.byAvatarCode,
          size: 26,
        ),
        Text(name, style: style),
      ],
    );
  }
}

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
