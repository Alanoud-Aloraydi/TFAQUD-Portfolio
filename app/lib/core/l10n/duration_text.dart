import 'package:app/core/l10n/arabic_counts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// A length of time: «3 دقائق», «ساعتين», «ساعة و5 دقائق».
String durationText(BuildContext context, int minutes) {
  if (minutes < 60) return arabicCount(context, ArabicCount.minutes, minutes);
  final String hours = arabicCount(context, ArabicCount.hours, minutes ~/ 60);
  if (minutes % 60 == 0) return hours;
  return context.tr(
    'counts.and',
    args: <String>[
      hours,
      arabicCount(context, ArabicCount.minutes, minutes % 60),
    ],
  );
}

/// How long after its time something was recorded, short enough for a
/// status badge: to the minute under 3 hours («ساعة و20 دقيقة»), whole
/// hours from there («5 ساعات»), and days from 2 days («يومين»).
String lateByText(BuildContext context, Duration late) {
  final int minutes = late.inMinutes < 1 ? 1 : late.inMinutes;
  if (minutes < 3 * 60) return durationText(context, minutes);
  if (minutes < 2 * 24 * 60) {
    return arabicCount(context, ArabicCount.hours, (minutes / 60).round());
  }
  return arabicCount(context, ArabicCount.days, (minutes / (24 * 60)).round());
}

/// How long ago a day was: «اليوم», «أمس», «قبل يومين», «قبل 5 أيام».
String daysAgo(BuildContext context, int days) {
  if (days <= 0) return context.tr('counts.today');
  if (days == 1) return context.tr('counts.yesterday');
  return context.tr(
    'counts.ago',
    args: <String>[arabicCount(context, ArabicCount.days, days)],
  );
}

/// «3 دقائق», «ساعتين», «ساعة و5 دقائق»: the length on its own, for a
/// sentence that is not «بعد ...», such as «فات موعده منذ ...».
String durationWords(BuildContext context, int minutes) {
  if (minutes < 60) {
    return arabicCount(context, ArabicCount.minutes, minutes);
  }
  final String hours = arabicCount(context, ArabicCount.hours, minutes ~/ 60);
  if (minutes % 60 == 0) return hours;
  return context.tr(
    'today_dashboard.and_minutes',
    args: <String>[
      hours,
      arabicCount(context, ArabicCount.minutes, minutes % 60),
    ],
  );
}

/// «بعد 3 دقائق», «بعد ساعتين», «بعد ساعة و5 دقائق».
String afterDuration(BuildContext context, int minutes) => context.tr(
  'today_dashboard.after',
  args: <String>[durationWords(context, minutes)],
);
