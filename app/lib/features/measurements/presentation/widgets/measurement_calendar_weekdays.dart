import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The short names of the days over a Saturday-first calendar.
class MeasurementCalendarWeekdays extends StatelessWidget {
  const MeasurementCalendarWeekdays({super.key});

  static const List<int> _weekdays = <int>[6, 7, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (final int day in _weekdays)
        Expanded(
          child: Center(
            child: Text(
              context.tr('medications.weekday_short.$day'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
    ],
  );
}
