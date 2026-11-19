import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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
