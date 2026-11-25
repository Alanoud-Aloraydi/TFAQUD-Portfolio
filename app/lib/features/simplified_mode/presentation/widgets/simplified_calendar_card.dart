import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «نوع التاريخ» under «حجم الخط»: two big tiles, هجري and ميلادي, each
/// with today written in it, as the text size has its three.
class SimplifiedCalendarCard extends StatelessWidget {
  const SimplifiedCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final DateCalendar chosen = CalendarScope.of(context);
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('calendar.kind'),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final DateCalendar calendar
                  in DateCalendar.values) ...<Widget>[
                if (calendar != DateCalendar.hijri) const SizedBox(width: 10),
                Expanded(
                  child: SimplifiedCalendarTile(
                    calendar: calendar,
                    selected: calendar == chosen,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One calendar to pick, «هجري» or «ميلادي», with today's day and month in
/// it; tinted with the thick ink edge when chosen, as a text size tile.
class SimplifiedCalendarTile extends StatelessWidget {
  const SimplifiedCalendarTile({
    super.key,
    required this.calendar,
    required this.selected,
  });

  final DateCalendar calendar;

  /// Whether this is the calendar chosen now.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final DateTime today = PatientClockScope.of(context).today();
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => AppCalendar.choose(calendar),
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: simplifiedTextSizeTileDecoration(selected: selected),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.tr('calendar.${calendar.name}'),
                style: SimplifiedStyle.head(SimplifiedStyle.body),
              ),
              const SizedBox(height: 4),
              Text(
                calendarDate(context, today, year: false, calendar: calendar),
                textAlign: TextAlign.center,
                style: SimplifiedStyle.text(SimplifiedStyle.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
