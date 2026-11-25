import 'package:app/core/utils/weekdays.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The days of a plan in words: «كل يوم» for the whole week, otherwise the
/// day names from Saturday, joined with the list separator.
String formatWeekdays(BuildContext context, Iterable<int> days) {
  if (isEveryDay(days)) return context.tr('weekday_picker.every_day');
  return <int>[
        for (final int day in weekOrder)
          if (days.contains(day)) day,
      ]
      .map((int day) => context.tr('medications.weekday.$day'))
      .join(context.tr('medications.list_separator'));
}
