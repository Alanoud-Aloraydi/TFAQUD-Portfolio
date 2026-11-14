import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The dots of the pages: the page on show is a longer ink bar. VoiceOver
/// reads «الخطوة 1 من 3».
class AuthDots extends StatelessWidget {
  const AuthDots({super.key, required this.count, required this.current});

  final int count;
  final int current;

  static const double _dot = 7;
  static const double _on = 24;

  @override
  Widget build(BuildContext context) {
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.contentEnter;
    return Semantics(
      label: context.tr(
        'common.step_of',
        args: <String>['${current + 1}', '$count'],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < count; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.tight),
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.easeOutCubic,
              width: i == current ? _on : _dot,
              height: _dot,
              decoration: ShapeDecoration(
                color: i == current
                    ? AppSemanticColors.textPrimary
                    : AppSemanticColors.introDotIdle,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
