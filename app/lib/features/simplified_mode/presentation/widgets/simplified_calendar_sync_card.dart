import 'dart:async';

import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_legal.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_square_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
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
        if (blocked)
          const SimplifiedPermissionDenied(
            messageKey: 'circle_overview.calendar_access_denied',
          )
        else if (enabled == true && access == AppPermission.partial)
          const SimplifiedPermissionDenied(
            messageKey: 'circle_overview.calendar_access_partial',
          )
        else
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

/// The calendar row: a calendar square, what goes on the calendar, a switch.
class SimplifiedCalendarRow extends StatelessWidget {
  const SimplifiedCalendarRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SimplifiedSwitchRow(
    icon: ScheduleIcons.calendar,
    background: AppSettingsTileColors.appointments,
    label: label,
    value: value,
    onChanged: onChanged,
  );
}
