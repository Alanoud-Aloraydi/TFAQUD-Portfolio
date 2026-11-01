import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/layout/step_progress.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Top of a step page: optional back link, title, optional subtitle.
///
/// A page that opens as a modal (it rises from the bottom, such as the
/// notifications and the account) has the close button (✕) in place of the
/// back link: [onClose] instead of [onBack].
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onClose,
    this.step,
    this.totalSteps,
  }) : assert(onBack == null || onClose == null),
       assert((step == null) == (totalSteps == null));

  final String title;
  final String? subtitle;

  /// Null hides the back link and keeps its space, so titles line up.
  final VoidCallback? onBack;

  /// The close button of a modal page, on the leading side (the right in
  /// Arabic), in glass as the buttons of the top bar.
  final VoidCallback? onClose;

  /// The page's place in a step-by-step flow, such as the first account
  /// set-up: the progress bar and «الخطوة 1 من 2» show above the title.
  final int? step;
  final int? totalSteps;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (onClose != null)
          GlassIconButton(
            tooltip: context.tr('common.close'),
            icon: const Icon(CupertinoIcons.xmark),
            onPressed: onClose,
          )
        else if (onBack != null)
          BackLink(onPressed: onBack!)
        else
          const SizedBox(height: AppSizes.touch),
        if (step != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          StepProgress(step: step!, total: totalSteps!),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              'common.step_of',
              args: <String>['$step', '$totalSteps'],
            ),
            style: text.bodySmall?.copyWith(color: AppColors.slate),
          ),
        ],
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
