import 'dart:math' as math;

import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_segment_track.dart';
import 'package:flutter/material.dart';

/// iOS segmented control on Liquid Glass (design system "TFAQUD",
/// SegmentedControl): a glass capsule, at least 44 high, with the chosen
/// segment on a neutral translucent capsule that slides to it.
///
/// The thumb sits 4 inside the track and is a capsule too, so the two are
/// concentric. The chosen segment is also bolder and in ink. In a
/// right-to-left language the first segment is on the right.
class GlassSegmentedControl<T extends Object> extends StatelessWidget {
  const GlassSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    this.onChanged,
    this.enabledValues,
    this.counts,
  });

  /// The segments in reading order: value and label.
  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T>? onChanged;

  /// Null enables every segment. Unavailable sections remain visible but inert.
  final Set<T>? enabledValues;

  /// Optional live count displayed beside each segment label.
  final Map<T, int>? counts;

  @override
  Widget build(BuildContext context) {
    final List<T> values = segments.keys.toList(growable: false);
    final int index = math.max(0, values.indexOf(selected));
    final ValueChanged<T>? change = onChanged;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.touch),
      child: GlassSurface(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSizes.touch / 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppGlass.segmentInset),
          child: GlassSegmentTrack(
            labels: <String>[for (final T v in values) segments[v]!],
            counts: <int?>[for (final T v in values) counts?[v]],
            enabled: <bool>[
              for (final T v in values) enabledValues?.contains(v) ?? true,
            ],
            index: index,
            onPick: change == null ? null : (int i) => change(values[i]),
          ),
        ),
      ),
    );
  }
}

/// The capsule that slides under the chosen segment of a segmented control:
/// the [index]th of segments [width] wide each.
class GlassSegmentThumb extends StatelessWidget {
  const GlassSegmentThumb({
    super.key,
    required this.index,
    required this.width,
  });

  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return AnimatedPositionedDirectional(
      duration: still ? Duration.zero : AppMotion.segmentSlide,
      curve: AppMotion.easeOutCubic,
      start: index * width,
      width: width,
      top: 0,
      bottom: 0,
      child: const DecoratedBox(
        decoration: ShapeDecoration(
          shape: StadiumBorder(),
          color: AppGlass.normalBottom,
          shadows: AppEffects.segmentShadow,
        ),
      ),
    );
  }
}
