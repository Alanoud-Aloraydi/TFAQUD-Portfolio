import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The progress of a step-by-step flow: one short bar per step, the done
/// steps and the current one in `ink`, the rest in `line`. The bar of the
/// new step fills in when the page opens, so moving forward is felt. The
/// words under it («الخطوة 1 من 3») say the same, so the bars are hidden
/// from VoiceOver.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});

  /// The current step, from 1 to [total].
  final int step;
  final int total;

  static const double _height = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          for (int i = 1; i <= total; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: i < total ? AppSpacing.sm : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_height / 2),
                  child: ColoredBox(
                    color: AppSemanticColors.borderSubtle,
                    child: SizedBox(
                      height: _height,
                      child: i < step
                          ? const ColoredBox(
                              color: AppSemanticColors.textPrimary,
                            )
                          : i == step
                          // The current step fills from the start side.
                          ? TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: still ? 1 : 0,
                                end: 1,
                              ),
                              duration: AppMotion.menuEnter,
                              curve: AppMotion.easeOutCubic,
                              builder: (BuildContext context, double t, _) =>
                                  FractionallySizedBox(
                                    alignment: AlignmentDirectional.centerStart,
                                    widthFactor: t,
                                    child: const ColoredBox(
                                      color: AppSemanticColors.textPrimary,
                                    ),
                                  ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
