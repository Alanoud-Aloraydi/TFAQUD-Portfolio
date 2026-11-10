import 'dart:math' as math;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_effects.dart';
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
    final bool still = MediaQuery.disableAnimationsOf(context);
    final TextTheme text = Theme.of(context).textTheme;
    final AppTokens tokens = context.tokens;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.touch),
      child: GlassSurface(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSizes.touch / 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppGlass.segmentInset),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth / values.length;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: onChanged == null
                    ? null
                    : (details) {
                        final position =
                            Directionality.of(context) == TextDirection.rtl
                            ? constraints.maxWidth - details.localPosition.dx
                            : details.localPosition.dx;
                        final int next = math.min(
                          math.max((position / width).floor(), 0),
                          values.length - 1,
                        );
                        if (next == index ||
                            !(enabledValues?.contains(values[next]) ?? true)) {
                          return;
                        }
                        HapticFeedback.selectionClick();
                        onChanged?.call(values[next]);
                      },
                child: Stack(
                  children: <Widget>[
                    AnimatedPositionedDirectional(
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
                    ),
                    Row(
                      children: <Widget>[
                        for (int i = 0; i < values.length; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == index,
                              enabled:
                                  enabledValues?.contains(values[i]) ?? true,
                              inMutuallyExclusiveGroup: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (onChanged == null ||
                                      i == index ||
                                      !(enabledValues?.contains(values[i]) ??
                                          true)) {
                                    return;
                                  }
                                  HapticFeedback.selectionClick();
                                  onChanged?.call(values[i]);
                                },
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight:
                                        AppSizes.touch -
                                        2 * AppGlass.segmentInset,
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
                                              segments[values[i]]!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: text.titleSmall?.copyWith(
                                                color:
                                                    !(enabledValues?.contains(
                                                          values[i],
                                                        ) ??
                                                        true)
                                                    ? tokens.textSecondary
                                                    : i == index
                                                    ? AppSemanticColors
                                                          .textPrimary
                                                    : tokens.textSecondary,
                                                fontWeight: i == index
                                                    ? AppTextTheme.bold
                                                    : AppTextTheme.medium,
                                              ),
                                            ),
                                          ),
                                          if (counts?[values[i]]
                                              case final count?) ...[
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                            Text(
                                              '$count',
                                              style: text.labelSmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
