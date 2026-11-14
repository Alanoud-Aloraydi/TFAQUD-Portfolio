import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «وضع تطبيق المريض: **تفصيلي**», and under it why it cannot be changed
/// here.
class CircleAppModeRow extends StatelessWidget {
  const CircleAppModeRow({super.key, required this.mode});

  final CircleAppMode? mode;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String value = context.tr(
      mode == CircleAppMode.simplified
          ? 'circle_overview.simplified'
          : 'circle_overview.detailed',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              AppIcons.idCard,
              size: AppSizes.iconSmall,
              color: AppSemanticColors.textSupporting,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '${context.tr('circle_overview.app_mode')} ',
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        color: AppSemanticColors.textPrimary,
                        fontWeight: AppTextTheme.semibold,
                      ),
                    ),
                  ],
                ),
                style: text.bodySmall,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSizes.iconSmall + AppSpacing.sm,
          ),
          child: Text(
            context.tr('circle_overview.mode_note'),
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }
}
