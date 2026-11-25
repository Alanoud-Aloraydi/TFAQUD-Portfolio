import 'dart:math' as math;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// One segment of a [GlassSegmentedControl]: its label, the optional live
/// count beside it and the tap that chooses it.
class GlassSegment extends StatelessWidget {
  const GlassSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppTokens tokens = context.tokens;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.touch - 2 * AppGlass.segmentInset,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: !enabled
                              ? tokens.textSecondary
                              : selected
                              ? AppSemanticColors.textPrimary
                              : tokens.textSecondary,
                          fontWeight: selected
                              ? AppTextTheme.bold
                              : AppTextTheme.medium,
                        ),
                      ),
                    ),
                    if (count case final count?) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text('$count', style: text.labelSmall),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
