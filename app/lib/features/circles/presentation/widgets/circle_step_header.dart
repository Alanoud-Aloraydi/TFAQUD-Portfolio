import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/layout/step_progress.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Top of a circle creation step: back link, a bar of three segments, the line
/// "الخطوة 1 من 3 · ...", the title and an optional subtitle.
class CircleStepHeader extends StatelessWidget {
  const CircleStepHeader({
    super.key,
    required this.step,
    required this.stepTitle,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  /// The number of steps of the flow.
  static const int totalSteps = 3;

  /// The current step, from 1 to [totalSteps].
  final int step;

  /// The name of the step, written after the step number.
  final String stepTitle;

  final String title;
  final String? subtitle;

  /// Null hides the back link and keeps its space, so titles line up.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (onBack != null)
          BackLink(onPressed: onBack!)
        else
          const SizedBox(height: 44),
        const SizedBox(height: AppSpacing.sm),
        // The line below says the same in words, so the bars are not read.
        StepProgress(step: step, total: totalSteps),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(
            'circles.step',
            args: <String>['$step', '$totalSteps', stepTitle],
          ),
          style: text.bodySmall?.copyWith(color: AppColors.slate),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(header: true, child: Text(title, style: text.headlineMedium)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: AppColors.slate),
          ),
        ],
      ],
    );
  }
}
