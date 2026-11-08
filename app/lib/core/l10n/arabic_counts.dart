import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Arabic counted words, the way they are said: «دقيقة» (1), «دقيقتين» (2),
/// «3 دقائق» to «10 دقائق», then «11 دقيقة» and on. The forms are the
/// `counts.*` keys (zero, one, two, few, many, other), chosen by Arabic's
/// plural rules in [arabicPluralForm].
enum ArabicCount { minutes, hours, days }

/// Which plural form Arabic uses for [count] (the CLDR rules): 0 zero, 1 one,
/// 2 two, 3 to 10 few, 11 to 99 many, and 100, 101, 102 other; past 100
/// the last two digits decide, so 103 is few.
///
/// The app chooses it here rather than with `context.plural`: by default
/// easy_localization ignores a language's own rules and says «other» for
/// every number past 2, which would be «3 يوم».
String arabicPluralForm(int count) {
  if (count == 0) return 'zero';
  if (count == 1) return 'one';
  if (count == 2) return 'two';
  final int lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'few';
  if (lastTwo >= 11) return 'many';
  return 'other';
}

/// [count] of [unit], «3 دقائق».
String arabicCount(BuildContext context, ArabicCount unit, int count) =>
    context.tr(
      'counts.${unit.name}.${arabicPluralForm(count)}',
      args: <String>['$count'],
    );

/// «بعد 3 دقائق», «بعد ساعتين», «بعد ساعة و5 دقائق».
String afterDuration(BuildContext context, int minutes) {
  if (minutes < 60) {
    return context.tr(
      'today_dashboard.after',
      args: <String>[arabicCount(context, ArabicCount.minutes, minutes)],
    );
  }
  final String hours = arabicCount(context, ArabicCount.hours, minutes ~/ 60);
  if (minutes % 60 == 0) {
    return context.tr('today_dashboard.after', args: <String>[hours]);
  }
  return context.tr(
    'today_dashboard.after_and',
    args: <String>[
      hours,
      arabicCount(context, ArabicCount.minutes, minutes % 60),
    ],
  );
}

/// «صباح الخير، ياسر» before noon in Riyadh ([now] is Riyadh's wall time),
/// «مساء الخير، ياسر» after it; without a name, the greeting alone.
String greeting(BuildContext context, DateTime now, String? name) {
  final String key = now.hour < 12
      ? 'today_dashboard.good_morning'
      : 'today_dashboard.good_evening';
  final String? shown = name?.trim();
  return shown == null || shown.isEmpty
      ? context.tr(key)
      : context.tr('${key}_name', args: <String>[shown]);
}
