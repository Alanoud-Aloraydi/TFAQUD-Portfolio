import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/refresh_stage.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What shows in the gap a pulled page opens at its top: the loader,
/// growing and turning with the pull until [reach] lets go, and under it
/// what the [stage] says. [height] is how far the page is open over it.
class RefreshHeader extends StatelessWidget {
  const RefreshHeader({
    super.key,
    required this.stage,
    required this.height,
    required this.reach,
  });

  final RefreshStage stage;
  final double height;
  final double reach;

  @override
  Widget build(BuildContext context) {
    final String? words = stage.wordsKey;
    if (words == null || height <= 0) return const SizedBox.shrink();
    final double grown = (height / reach).clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          maxHeight: double.infinity,
          child: Opacity(
            opacity: grown,
            child: Semantics(
              liveRegion: stage.isHeld,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TfaqudLoader(
                    size: 20 + 20 * grown,
                    animating: stage == RefreshStage.loading,
                    turn: grown / 2,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr(words),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: context.tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
