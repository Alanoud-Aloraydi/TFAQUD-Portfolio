import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/pickers/date_wheel_ranges.dart';
import 'package:app/core/widgets/pickers/date_wheel_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The wheels of the date sheet; with [offerCalendars], the هجري | ميلادي
/// capsule above them and «يوافق …», the date in the other calendar,
/// under them.
class DateWheelBody extends StatelessWidget {
  const DateWheelBody({
    super.key,
    required this.ranges,
    required this.day,
    required this.date,
    required this.offerCalendars,
    required this.onSelected,
    required this.onCalendar,
  });

  final DateWheelRanges ranges;
  final int day;

  /// The chosen day, for the other calendar's line.
  final DateTime date;
  final bool offerCalendars;
  final void Function({int? year, int? month, int? day}) onSelected;
  final ValueChanged<DateCalendar> onCalendar;

  @override
  Widget build(BuildContext context) {
    final DateCalendar shown = ranges.calendar;
    final DateCalendar other = shown == DateCalendar.hijri
        ? DateCalendar.gregorian
        : DateCalendar.hijri;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (offerCalendars) ...<Widget>[
          GlassSegmentedControl<DateCalendar>(
            segments: <DateCalendar, String>{
              DateCalendar.hijri: context.tr('calendar.hijri'),
              DateCalendar.gregorian: context.tr('calendar.gregorian'),
            },
            selected: shown,
            onChanged: onCalendar,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // Built again on another calendar: its wheels start on the new day.
        DateWheelRow(
          key: ValueKey<DateCalendar>(shown),
          ranges: ranges,
          day: day,
          onSelected: onSelected,
        ),
        if (offerCalendars) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr(
              'calendar.matches',
              args: <String>[calendarDateWithEra(context, date, other)],
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppSemanticColors.textSupporting),
          ),
        ],
      ],
    );
  }
}
