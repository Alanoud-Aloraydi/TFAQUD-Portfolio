import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The month name with arrows to move between months. The forward arrow is
/// off on the current month: there is nothing to read after it.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.canGoForward,
    required this.onChange,
  });

  final DateTime month;
  final bool canGoForward;

  /// Called with -1 for the month before, 1 for the month after.
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: context.tr('measurements.previous_month'),
          onPressed: () => onChange(-1),
          icon: const Icon(CupertinoIcons.chevron_right),
        ),
        Expanded(
          child: Text(
            '${context.tr('circles.months.${month.month}')} ${month.year}',
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
