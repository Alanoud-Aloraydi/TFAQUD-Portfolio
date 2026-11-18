import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The round mark at the top of the waiting page, and the two lines that
/// say whether the request is still waiting or was answered.
class RequestSentHeader extends StatelessWidget {
  const RequestSentHeader({super.key, required this.accepted});

  /// The round mark, large enough to be the first thing on the page.
  static const double markSize = 72;

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Container(
          width: markSize,
          height: markSize,
          decoration: const BoxDecoration(
            color: AppSemanticColors.surfaceContent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            accepted ? ActionIcons.check : ScheduleIcons.clock,
            size: AppSizes.iconEmpty,
            color: accepted
                ? AppSemanticColors.statusSuccess
                : context.tokens.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            context.tr(
              accepted
                  ? 'circles.request_accepted_title'
                  : 'circles.request_waiting_title',
            ),
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(
            accepted
                ? 'circles.request_accepted_body'
                : 'circles.request_waiting_body',
          ),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
