import 'dart:async';

import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/core/widgets/layout/toggle_row.dart';
import 'package:flutter/material.dart';

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
