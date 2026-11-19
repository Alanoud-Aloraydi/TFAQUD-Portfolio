import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The simplified mode's way of writing a time: آ«6:00 ظ…ط³ط§ط،ظ‹آ».
String simplifiedTime(BuildContext context, String time) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final String minute = parts[1].padLeft(2, '0');
  final String period = context.tr(
    hour < 12 ? 'simplified_mode.am' : 'simplified_mode.pm',
  );
  return '${hour % 12 == 0 ? 12 : hour % 12}:$minute $period';
}

/// The patient's clock time at the instant [at]: آ«2:09 ظ…ط³ط§ط،ظ‹آ».
String simplifiedClockAt(BuildContext context, DateTime at) {
  final DateTime wall = PatientClockScope.of(context).wallTime(at);
  return simplifiedTime(
    context,
    '${wall.hour}:${wall.minute.toString().padLeft(2, '0')}',
  );
}

/// آ«ط§ظ„ظٹظˆظ…طŒ ط§ظ„ط¬ظ…ط¹ط© 6 ظ†ظˆظپظ…ط¨ط±آ».
String simplifiedToday(BuildContext context, DateTime now) {
  final DateTime day = PatientClockScope.of(context).today(now);
  final parts = calendarParts(context, day);
  return context.tr(
    'simplified_mode.today_date',
    args: <String>[
      context.tr('common.weekdays.${day.weekday}'),
      '${parts.day}',
      parts.month,
    ],
  );
}

/// How long until [at] (the patient's wall time) from the instant [now],
/// in the detailed mode's words: آ«ط¨ط¹ط¯ ط³ط§ط¹طھظٹظ†آ», آ«ط¨ط¹ط¯ 3 ط¯ظ‚ط§ط¦ظ‚آ», or آ«ط§ظ„ط¢ظ†آ»
/// once it came.
String simplifiedUntil(BuildContext context, DateTime at, DateTime now) {
  final DateTime wall = PatientClockScope.of(context).wallTime(now);
  final int minutes = at.difference(wall).inMinutes;
  if (minutes <= 0) return context.tr('simplified_mode.now');
  return afterDuration(context, minutes);
}
