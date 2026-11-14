import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_circle_row.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_section.dart';
import 'package:flutter/material.dart';

/// The circles in one group, a switch each: on copies that circle's doses,
/// measurement times and appointments to the phone's calendar.
class CalendarSyncCircleList extends StatelessWidget {
  const CalendarSyncCircleList({super.key, required this.circles});

  final List<CalendarSyncCircle> circles;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: <Widget>[
        for (final CalendarSyncCircle circle in circles)
          CalendarSyncCircleRow(
            key: ValueKey<String>(circle.id),
            circleId: circle.id,
            name: circle.name,
            leading: circle.leading,
          ),
      ],
    );
  }
}
