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
/// segment on a pale green capsule that slides to it.
///
/// The thumb sits 4 inside the track and is a capsule too, so the two are
/// concentric. The chosen segment is also bolder and in ink, so the green is
/// never the only sign. In a right-to-left language the first segment is on
/// the right.
class GlassSegmentedControl<T extends Object> extends StatelessWidget {
  const GlassSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  /// The segments in reading order: value and label.
  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

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
              return Stack(
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
                        color: AppSemanticColors.selectedSurface,
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
                            inMutuallyExclusiveGroup: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (i == index) return;
                                HapticFeedback.selectionClick();
                                onChanged(values[i]);
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
                                    child: Text(
                                      segments[values[i]]!,
                                      textAlign: TextAlign.center,
                                      style: text.titleSmall?.copyWith(
                                        color: i == index
                                            ? AppSemanticColors.textPrimary
                                            : tokens.textSecondary,
                                        fontWeight: i == index
                                            ? AppTextTheme.bold
                                            : AppTextTheme.medium,
                                      ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
