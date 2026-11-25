import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/navigation/glass_icon_button.dart';
import 'package:easy_localization/easy_localization.dart';
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
    this.trailing,
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

  /// A button at the end of the top row, across from back or close (the
  /// left in Arabic), such as «تعديل» on the account page.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeaderTopRow(onBack: onBack, onClose: onClose, trailing: trailing),
        if (step != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          StepProgress(step: step!, total: totalSteps!),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              'common.step_of',
              args: <String>['$step', '$totalSteps'],
            ),
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Semantics(header: true, child: Text(title, style: text.headlineMedium)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// The top row of a [StepHeader]: close (✕) or back on the leading side,
/// or an empty space of the same height, and an optional [trailing] button
/// across from it.
class StepHeaderTopRow extends StatelessWidget {
  const StepHeaderTopRow({super.key, this.onBack, this.onClose, this.trailing});

  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onClose != null)
          GlassIconButton(
            tooltip: context.tr('common.close'),
            icon: const Icon(ActionIcons.x),
            onPressed: onClose,
          )
        else if (onBack != null)
          BackLink(onPressed: onBack!)
        else
          const SizedBox(height: AppSizes.touch),
        if (trailing case final Widget end) ...<Widget>[const Spacer(), end],
      ],
    );
  }
}

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
