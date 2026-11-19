import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The month name with arrows to move between months. The forward arrow is
/// off on the current month: there is nothing to read after it; the back
/// arrow on the first month with something to read.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.canGoForward,
    required this.onChange,
    this.canGoBack = true,
  });

  final CalendarMonth month;
  final bool canGoForward;
  final bool canGoBack;

  /// Called with -1 for the month before, 1 for the month after.
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: context.tr('measurements.previous_month'),
          onPressed: canGoBack ? () => onChange(-1) : null,
          icon: const Icon(CupertinoIcons.chevron_right),
        ),
        Expanded(
          child: Text(
            calendarMonthTitle(context, month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: context.tr('measurements.next_month'),
          onPressed: canGoForward ? () => onChange(1) : null,
          icon: const Icon(CupertinoIcons.chevron_left),
        ),
      ],
    );
  }
}
