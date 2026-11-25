import 'dart:async';

import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/layout/toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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

/// One circle's calendar switch: on copies its doses, its measurement times
/// and its appointments to the phone's calendar, off takes them off again.
/// One switch per circle, not one per kind.
class CalendarSyncCircleRow extends StatefulWidget {
  const CalendarSyncCircleRow({
    super.key,
    required this.circleId,
    required this.name,
    this.leading,
  });

  final String circleId;

  final String name;
  final Widget? leading;

  @override
  State<CalendarSyncCircleRow> createState() => _CircleCalendarState();
}

class _CircleCalendarState extends State<CalendarSyncCircleRow>
    with CalendarSyncChoices<CalendarSyncCircleRow> {
  @override
  String get calendarCircleId => widget.circleId;

  @override
  Widget build(BuildContext context) {
    return ToggleRow(
      label: widget.name,
      leading: widget.leading,
      value: enabled ?? false,
      onChanged: (bool value) => unawaited(setChoice(value)),
    );
  }
}

/// One circle in a [CalendarSyncCircleList]: its id, the name shown, and a
/// small picture before the name (the patient's photo).
typedef CalendarSyncCircle = ({String id, String name, Widget? leading});
