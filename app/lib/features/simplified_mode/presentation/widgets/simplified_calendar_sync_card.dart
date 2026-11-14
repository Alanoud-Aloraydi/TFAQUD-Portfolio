import 'dart:async';

import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The circle's medicines, measurement times and appointments on the
/// phone's own calendar: one switch, in this mode's sizes. The same choice
/// the detailed mode keeps, through the same [CalendarSync]; off until
/// chosen.
class SimplifiedCalendarSyncCard extends StatefulWidget {
  const SimplifiedCalendarSyncCard({super.key, required this.circleId});

  final String circleId;

  @override
  State<SimplifiedCalendarSyncCard> createState() =>
      _SimplifiedCalendarSyncCardState();
}

class _SimplifiedCalendarSyncCardState extends State<SimplifiedCalendarSyncCard>
    with CalendarSyncChoices<SimplifiedCalendarSyncCard> {
  @override
  String get calendarCircleId => widget.circleId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SimplifiedCard(
          padding: const EdgeInsets.symmetric(horizontal: SimplifiedStyle.pad),
          child: SimplifiedCalendarRow(
            label: context.tr('simplified_mode.calendar_switch'),
            value: enabled ?? false,
            onChanged: enabled == null
                ? null
                : (bool value) => unawaited(setChoice(value)),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: 8,
            start: SimplifiedStyle.pad,
            end: SimplifiedStyle.pad,
          ),
          child: Text(
            context.tr('simplified_mode.calendar_text'),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
        ),
      ],
    );
  }
}
