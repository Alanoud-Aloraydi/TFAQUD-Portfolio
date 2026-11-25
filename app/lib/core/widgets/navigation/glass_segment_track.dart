import 'dart:math' as math;

import 'package:app/core/widgets/navigation/glass_segment.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The inside of a segmented control: the thumb that slides under the
/// chosen segment and the row of segments. A tap or a horizontal drag asks
/// [onPick] for another segment, by index, unless it is the chosen one or an
/// unavailable one; a null [onPick] makes the control inert.
class GlassSegmentTrack extends StatelessWidget {
  const GlassSegmentTrack({
    super.key,
    required this.labels,
    required this.counts,
    required this.enabled,
    required this.index,
    required this.onPick,
  });

  final List<String> labels;
  final List<int?> counts;
  final List<bool> enabled;
  final int index;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth / labels.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: onPick == null
              ? null
              : (details) {
                  final int? next = glassSegmentDragTarget(
                    dx: details.localPosition.dx,
                    maxWidth: constraints.maxWidth,
                    direction: Directionality.of(context),
                    count: labels.length,
                    current: index,
                    isEnabled: (int i) => enabled[i],
                  );
                  if (next == null) return;
                  HapticFeedback.selectionClick();
                  onPick?.call(next);
                },
          child: Stack(
            children: <Widget>[
              GlassSegmentThumb(index: index, width: width),
              Row(
                children: <Widget>[
                  for (int i = 0; i < labels.length; i++)
                    GlassSegment(
                      label: labels[i],
                      selected: i == index,
                      enabled: enabled[i],
                      count: counts[i],
                      onTap: () {
                        if (onPick == null || i == index || !enabled[i]) return;
                        HapticFeedback.selectionClick();
                        onPick?.call(i);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

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
