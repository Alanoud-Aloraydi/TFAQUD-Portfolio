import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The segment a horizontal drag at [dx] reaches in a control [maxWidth]
/// wide with [count] equal segments, or null when it is the [current] one or
/// an unavailable one ([isEnabled] says which). In a right-to-left language
/// the first segment is on the right, so the position is counted from there.
int? glassSegmentDragTarget({
  required double dx,
  required double maxWidth,
  required TextDirection direction,
  required int count,
  required int current,
  required bool Function(int index) isEnabled,
}) {
  final double width = maxWidth / count;
  final double position = direction == TextDirection.rtl ? maxWidth - dx : dx;
  final int next = math.min(math.max((position / width).floor(), 0), count - 1);
  if (next == current || !isEnabled(next)) return null;
  return next;
}
