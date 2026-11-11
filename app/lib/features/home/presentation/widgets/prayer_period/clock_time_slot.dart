import 'dart:math' as math;

import 'package:app/core/l10n/arabic_names.dart';
import 'package:flutter/material.dart';

/// Two times with the widest text of a 12-hour clock, one for each of
/// «ص» and «م»: the slot is as wide as the wider of them.
const List<String> _widestClockTimes = <String>['10:00', '22:00'];

/// A clock time in a slot that is the same width in every row and ends the
/// text at the end side, so a column of them lines up. Digits are tabular,
/// and the slot is measured at the current text size instead of using a
/// fixed offset, so it grows with large text.
class ClockTimeSlot extends StatelessWidget {
  const ClockTimeSlot({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return SizedBox(
      width: _slotWidth(context, style),
      child: Text(
        time,
        style: style,
        textAlign: TextAlign.end,
        softWrap: false,
      ),
    );
  }
}

double _slotWidth(BuildContext context, TextStyle style) {
  final TextStyle full = DefaultTextStyle.of(context).style.merge(style);
  double widest = 0;
  for (final String sample in _widestClockTimes) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: clockText(sample), style: full),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }
  return widest.ceilToDouble();
}
