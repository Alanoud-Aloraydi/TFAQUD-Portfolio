import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile_decoration.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

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
